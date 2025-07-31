from fastapi import FastAPI, HTTPException, Query, Request, Depends, status, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import googlemaps
import json
import re
import unicodedata
from math import radians, sin, cos, sqrt, atan2
import os
from dotenv import load_dotenv
import requests
from sqlmodel import Field, Session, SQLModel, create_engine, select
from datetime import datetime, timedelta
from twilio.rest import Client # Import Twilio Client
from googlemaps.convert import decode_polyline

# New imports for authentication
from passlib.context import CryptContext
from jose import JWTError, jwt
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer

# --- AUTHENTICATION CONFIGURATION ---
SECRET_KEY = os.getenv("SECRET_KEY", "super-secret-key") # CHANGE THIS IN PRODUCTION!
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- MODELS ---

class User(SQLModel, table=True, extend_existing=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(index=True, unique=True)
    hashed_password: str
    email: Optional[str] = Field(default=None, index=True, unique=True)
    is_active: bool = Field(default=True)

class UserCreate(BaseModel):
    username: str
    password: str
    email: Optional[str] = None

class UserInDB(BaseModel):
    username: str
    hashed_password: str
    email: Optional[str] = None
    is_active: bool = True

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    username: Optional[str] = None

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, vehicle_id: str):
        await websocket.accept()
        self.active_connections[vehicle_id] = websocket

    def disconnect(self, vehicle_id: str):
        del self.active_connections[vehicle_id]

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections.values():
            await connection.send_text(message)

manager = ConnectionManager()

# --- CONFIGURATION ---
load_dotenv() # Charge les variables depuis le fichier .env

# Clé API Google Maps (optionnelle)
API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "VOTRE_CLE_API_ICI")

# Initialisation de Google Maps (si la clé API est fournie)
if API_KEY != "VOTRE_CLE_API_ICI" and API_KEY != "":
    gmaps = googlemaps.Client(key=API_KEY)
else:
    gmaps = None
    print("Avertissement: Clé API Google Maps non configurée. Certaines fonctionnalités seront limitées.")

# Clé API Notch Pay (requise pour le paiement)
NOTCH_PAY_PUBLIC_KEY = os.getenv("NOTCH_PAY_PUBLIC_KEY")
# print(f"DEBUG: NOTCH_PAY_PUBLIC_KEY lue: {NOTCH_PAY_PUBLIC_KEY}") # Ligne de débogage temporaire
NOTCH_PAY_API_URL = "https://api.notchpay.co/payments" # Endpoint corrigé

# URL publique de notre serveur (à configurer pour le déploiement)
# Pour les tests locaux, on utilisera un outil comme ngrok
APP_BASE_URL = os.getenv("APP_BASE_URL", "http://127.0.0.1:8000")

# Configuration de la base de données SQLite
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./database.db") # Utilise PostgreSQL en prod, SQLite en dev
engine = create_engine(DATABASE_URL, echo=True)

# Configuration Twilio
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE_NUMBER = os.getenv("TWILIO_PHONE_NUMBER")
TEST_SMS_RECIPIENT_NUMBER = os.getenv("TEST_SMS_RECIPIENT_NUMBER") # Nouveau: pour les tests

try:
    twilio_client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
except Exception as e:
    print(f"Avertissement: Impossible d'initialiser le client Twilio. Vérifiez les variables d'environnement: {e}")
    twilio_client = None

from fastapi.middleware.cors import CORSMiddleware

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Code à exécuter au démarrage
    global agences_data
    try:
        with open("agences.json", "r", encoding="utf-8") as f:
            agences_data = json.load(f)
        print("Données des agences chargées avec succès.")
    except FileNotFoundError:
        print("Erreur: Le fichier agences.json est introuvable.")
    except json.JSONDecodeError:
        print("Erreur: Impossible de décoder le fichier agences.json.")
    
    yield
    
    # Code à exécuter à l'arrêt (si nécessaire)
    print("Application arrêtée.")

app = FastAPI(
    title="API de Voyage avec Paiement et Gestion de Billets",
    description="Une API pour trouver des trajets, localiser des agences, gérer les paiements via Notch Pay et les billets.",
    version="1.6.0", # Ajout de l'envoi de SMS Twilio
    lifespan=lifespan
)

# --- CORS CONFIGURATION ---
origins = [
    "http://localhost",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
    "https://jolly-cuchufli-31847a.netlify.app" # REMPLACEZ CECI PAR L'URL DE VOTRE SITE NETLIFY
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

agences_data: List[Dict[str, Any]] = [] # Déclaration de la variable globale

# --- MODÈLES DE DONNÉES ---

class Ticket(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    notchpay_reference: str = Field(index=True) # Référence de la transaction Notch Pay
    status: str = Field(default="pending") # pending, completed, failed, cancelled
    amount: int
    currency: str = "XAF"
    email: str
    phone: str
    description: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class VehicleLocation(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    vehicle_id: str = Field(index=True, unique=True) # ID unique du véhicule (ex: numéro de bus)
    latitude: float
    longitude: float
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class PaiementRequest(BaseModel):
    email: str
    phone: str
    amount: int
    description: str
    customer_name: Optional[str] = "Client Test" # Ajout d'un nom client optionnel

class VehicleLocationUpdate(BaseModel):
    vehicle_id: str
    latitude: float
    longitude: float

# --- FONCTIONS UTILITAIRES ---

def normalize_text(text: str) -> str:
    """Normalise le texte en minuscules, sans accents et sans espaces superflus."""
    s = ''.join(c for c in unicodedata.normalize('NFD', text)
                if unicodedata.category(c) != 'Mn')
    return s.lower().strip() # Ajout de strip() pour enlever les espaces

def calculer_distance(lat1, lon1, lat2, lon2) -> float:
    """Calcule la distance en km entre deux points GPS (formule Haversine)."""
    R = 6371  # Rayon de la Terre en km
    dLat = radians(lat2 - lat1)
    dLon = radians(lon2 - lon1)
    a = sin(dLat / 2) * sin(dLat / 2) + cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon / 2) * sin(dLon / 2)
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return R * c

def create_db_and_tables():
    global _tables_created
    if not _tables_created:
        SQLModel.metadata.create_all(engine)
        _tables_created = True

def get_session():
    with Session(engine) as session:
        yield session

def send_sms(to_number: str, message_body: str):
    """Envoie un SMS via Twilio."""
    if not twilio_client or not TWILIO_PHONE_NUMBER:
        print("Erreur: Client Twilio non initialisé ou numéro Twilio manquant.")
        return
    try:
        message = twilio_client.messages.create(
            to=to_number,
            from_=TWILIO_PHONE_NUMBER,
            body=message_body
        )
        print(f"SMS envoyé à {to_number}. SID: {message.sid}")
    except Exception as e:
        print(f"Erreur lors de l'envoi du SMS à {to_number}: {e}")

def validate_password_strength(password: str):
    if len(password) < 8:
        raise HTTPException(status_code=400, detail="Le mot de passe doit contenir au moins 8 caractères")
    if not re.search(r'[A-Z]', password):
        raise HTTPException(status_code=400, detail="Le mot de passe doit contenir au moins une majuscule")
    if not re.search(r'[a-z]', password):
        raise HTTPException(status_code=400, detail="Le mot de passe doit contenir au moins une minuscule")
    if not re.search(r'[0-9]', password):
        raise HTTPException(status_code=400, detail="Le mot de passe doit contenir au moins un chiffre")
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        raise HTTPException(status_code=400, detail="Le mot de passe doit contenir au moins un caractère spécial")

# --- LOGIQUE MÉTIER ---

def trouver_trajet_disponible(depart: str, destination: str, date_voyage: Optional[str] = None) -> List[Dict[str, Any]]:
    trajets_trouves = []
    jour_semaine = None
    if date_voyage:
        try:
            # Convertir la date YYYY-MM-DD en nom de jour en français
            date_obj = datetime.strptime(date_voyage, "%Y-%m-%d")
            jours_fr = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
            jour_semaine = jours_fr[date_obj.weekday()]
        except ValueError:
            # Si le format de date est invalide, on ne filtre pas par jour
            jour_semaine = None

    depart_normalized = normalize_text(depart)
    destination_normalized = normalize_text(destination)

    for agence in agences_data:
        if normalize_text(agence.get('ville_depart', '')) == depart_normalized:
            for trajet in agence.get('trajets', []):
                if normalize_text(trajet.get('destination', '')) == destination_normalized:
                    # La logique de vérification du jour reste la même pour l'instant
                    # Si un jour est spécifié, on vérifie qu'il correspond
                    if jour_semaine and trajet.get('days_of_week') and jour_semaine not in trajet.get('days_of_week'):
                        continue # Ce trajet ne circule pas le jour demandé

                    # On ajoute la date au résultat pour la clarté
                    trajet_info = {
                        'agence': agence.get('nom_agence'),
                        'destination': trajet.get('destination'),
                        'latitude': trajet.get('latitude'),
                        'longitude': trajet.get('longitude'),
                        'prix_vip': trajet.get('prix_vip'),
                        'prix_classique': trajet.get('prix_classique'),
                        'heureDepart': trajet.get('departure'),
                        'dureeEstimee': trajet.get('duration'),
                        'date': date_voyage # Ajout de la date
                    }
                    trajets_trouves.append(trajet_info)
    return trajets_trouves

def obtenir_infos_google_maps(depart: str, destination: str) -> Optional[Dict[str, Any]]:
    if not gmaps:
        return None
    try:
        directions = gmaps.directions(depart, destination, mode="driving", language="fr")
        if not directions:
            return None

        leg = directions[0]['legs'][0]
        # Extraire la polyligne encodée
        encoded_polyline = directions[0]['overview_polyline']['points']
        # Décoder la polyligne
        decoded_polyline = decode_polyline(encoded_polyline)
        # Convertir les points décodés en un format plus simple (liste de listes [lat, lng])
        polyline_coords = [[point['lat'], point['lng']] for point in decoded_polyline]

        return {
            "distance": leg['distance']['text'],
            "duree": leg['duration']['text'],
            "etapes_cles": [re.sub('<[^<]+?>', '', step['html_instructions']) for step in leg['steps'][:5]],
            "polyline_coords": polyline_coords # Ajouter les coordonnées de la polyligne
        }
    except googlemaps.exceptions.ApiError as e:
        print(f"Erreur API Google : {e}")
        return None

# --- ÉVÉNEMENTS DE L'APPLICATION ---



# --- ROUTES DE L'API ---

@app.get("/", summary="Point de bienvenue")
def read_root():
    return {"message": "Bienvenue sur l'API de voyage !"}

@app.get("/agences/proches", summary="Trouver les agences les plus proches")
def trouver_agences_proches(
    latitude: float = Query(..., description="Latitude de l'utilisateur"), 
    longitude: float = Query(..., description="Longitude de l'utilisateur")
):
    if not agences_data:
        raise HTTPException(status_code=503, detail="Les données des agences ne sont pas disponibles.")

    agences_avec_distance = []
    for agence in agences_data:
        dist = calculer_distance(latitude, longitude, agence['latitude'], agence['longitude'])
        agence_info = agence.copy()
        agence_info['distance_km'] = round(dist, 2)
        agences_avec_distance.append(agence_info)
    
    return sorted(agences_avec_distance, key=lambda x: x['distance_km'])

@app.get("/trajets/", summary="Rechercher des trajets")
def rechercher_trajets(depart: str, destination: str, date: Optional[str] = Query(None, description="Date du voyage au format YYYY-MM-DD", examples=["2025-07-13"])):
    if not agences_data:
        raise HTTPException(status_code=503, detail="Les données des agences ne sont pas disponibles.")
    
    # Le paramètre 'date' est passé à la fonction de logique métier
    trajets = trouver_trajet_disponible(depart, destination, date)
    
    if not trajets:
        # Message d'erreur plus précis
        detail_message = f"Aucun trajet direct trouvé de {depart} à {destination}"
        if date:
            detail_message += f" pour la date {date}."
        else:
            detail_message += "."
        raise HTTPException(status_code=404, detail=detail_message)
        
    return trajets

@app.get("/trajets/details", summary="Obtenir les détails complets d'un trajet")
def get_trajet_details(depart: str, destination: str):
    if not agences_data:
        raise HTTPException(status_code=503, detail="Les données des agences ne sont pas disponibles.")
    trajets_locaux = trouver_trajet_disponible(depart, destination)
    if not trajets_locaux:
        raise HTTPException(status_code=404, detail="Aucun trajet direct trouvé dans nos agences.")
    infos_gmaps = obtenir_infos_google_maps(depart, destination)
    return {
        "trajets_disponibles": trajets_locaux,
        "details_google_maps": infos_gmaps or "Non disponible (vérifiez la clé API)"
    }

@app.post("/paiement/initier", summary="Initier une demande de paiement")
def initier_paiement(paiement_req: PaiementRequest, session: Session = Depends(get_session)):
    if not NOTCH_PAY_PUBLIC_KEY:
        raise HTTPException(status_code=500, detail="La clé API de paiement n'est pas configurée sur le serveur.")

    headers = {
        "Authorization": NOTCH_PAY_PUBLIC_KEY,
        "Content-Type": "application/json"
    }
    payload = {
        "amount": paiement_req.amount,
        "currency": "XAF",
        "customer": {
            "name": paiement_req.customer_name,
            "email": paiement_req.email,
            "phone": paiement_req.phone
        },
        "description": paiement_req.description,
        "callback": f"{APP_BASE_URL}/paiement/webhook" # L'URL que Notch Pay appellera
    }

    try:
        response = requests.post(NOTCH_PAY_API_URL, headers=headers, json=payload)
        response.raise_for_status() # Lève une exception pour les erreurs 4xx/5xx
        data = response.json()
        
        # --- DÉBOGAGE : Affiche la réponse brute de Notch Pay dans la console ---
        print("--- Réponse brute de Notch Pay ---")
        print(json.dumps(data, indent=2))
        print("----------------------------------")
        # --- FIN DÉBOGAGE ---

        payment_link = data.get("authorization_url")
        # CORRECTION : La référence est sous la clé 'transaction'
        reference = data.get("transaction", {}).get("reference")

        # --- NOUVEAU DÉBOGAGE : Affiche les valeurs extraites ---
        print(f"DEBUG: payment_link = {payment_link}")
        print(f"DEBUG: reference = {reference}")
        # --- FIN NOUVEAU DÉBOGAGE ---

        if response.ok and payment_link and reference:
            # Créer un enregistrement de billet en attente dans la base de données
            ticket = Ticket(
                notchpay_reference=reference,
                status="pending",
                amount=paiement_req.amount,
                email=paiement_req.email,
                phone=paiement_req.phone,
                description=paiement_req.description
            )
            session.add(ticket)
            session.commit()
            session.refresh(ticket)

            return {
                "message": "Lien de paiement généré avec succès.",
                "payment_link": payment_link,
                "reference": reference,
                "ticket_id": ticket.id
            }
        else:
            raise HTTPException(status_code=400, detail=f"Erreur de l'API Notch Pay: {data.get('message', 'Réponse invalide')}")

    except requests.exceptions.RequestException as e:
        print(f"ERREUR DE REQUÊTE NOTCH PAY: {e}") # Ajout du débogage détaillé
        raise HTTPException(status_code=503, detail=f"Impossible de contacter le service de paiement: {e}")
    except Exception as e:
        print(f"ERREUR INATTENDUE: {e}") # Ajout du débogage détaillé
        raise HTTPException(status_code=500, detail=f"Une erreur inattendue est survenue: {e}")

@app.post("/paiement/webhook", summary="Webhook pour les notifications de paiement") # Changé de POST à GET
async def paiement_webhook(reference: str = Query(...), status: str = Query(...), session: Session = Depends(get_session)):
    """
    Reçoit les notifications de statut de paiement de la part de Notch Pay (via GET).
    Met à jour le statut du billet dans la base de données.
    """
    try:
        print("--- Webhook Notch Pay Reçu (GET) ---")
        print(f"Référence: {reference}")
        print(f"Statut: {status}")
        print("----------------------------------")

        # Mettre à jour le statut du billet dans la base de données
        ticket = session.exec(select(Ticket).where(Ticket.notchpay_reference == reference)).first()
        if ticket:
            ticket.status = status # 'complete' ou 'failed'
            ticket.updated_at = datetime.utcnow()
            session.add(ticket)
            session.commit()
            session.refresh(ticket)
            print(f"Statut du billet {ticket.id} mis à jour à: {status}")
            
            # --- ENVOI DU SMS DE CONFIRMATION ---
            if status == "complete":
                # Utilise TEST_SMS_RECIPIENT_NUMBER si défini, sinon le numéro du billet
                recipient_phone = TEST_SMS_RECIPIENT_NUMBER if TEST_SMS_RECIPIENT_NUMBER else ticket.phone
                sms_message = f"Votre billet de voyage (Ref: {ticket.notchpay_reference}) est confirmé ! Montant: {ticket.amount} {ticket.currency}. Destination: {ticket.description}."
                send_sms(recipient_phone, sms_message)
            # --- FIN ENVOI DU SMS ---

        else:
            print(f"Billet avec référence {reference} non trouvé.")

        return {"status": "received", "reference": reference, "status_from_notchpay": status}
    except Exception as e:
        print(f"Erreur lors du traitement du webhook: {e}")
        raise HTTPException(status_code=500, detail="Erreur interne du serveur.")

@app.post("/billet/annuler/{ticket_id}", summary="Annuler un billet")
def annuler_billet(ticket_id: int, session: Session = Depends(get_session)):
    """
    Met à jour le statut d'un billet à 'cancelled'.
    """
    ticket = session.get(Ticket, ticket_id)
    if not ticket:
        raise HTTPException(status_code=404, detail="Billet non trouvé")

    if ticket.status == "completed":
        ticket.status = "cancelled"
        ticket.updated_at = datetime.utcnow()
        session.add(ticket)
        session.commit()
        session.refresh(ticket)
        return {"message": "Billet annulé avec succès", "ticket_id": ticket.id, "new_status": "cancelled"}
    elif ticket.status == "cancelled":
        raise HTTPException(status_code=400, detail="Le billet a déjà été annulé.")
    else:
        raise HTTPException(status_code=400, detail=f"Le billet ne peut pas être annulé car son statut est '{ticket.status}'.")

# New User Authentication Routes

@app.post("/register", response_model=User, summary="Enregistrer un nouvel utilisateur")
def register_user(user: UserCreate, session: Session = Depends(get_session)):
    validate_password_strength(user.password)
    db_user_by_username = session.exec(select(User).where(User.username == user.username)).first()
    if db_user_by_username:
        raise HTTPException(status_code=400, detail="Nom d'utilisateur déjà enregistré")

    # Vérifier l'unicité de l'e-mail uniquement s'il est fourni (non vide)
    if user.email:
        db_user_by_email = session.exec(select(User).where(User.email == user.email)).first()
        if db_user_by_email:
            raise HTTPException(status_code=400, detail="Adresse e-mail déjà enregistrée")

    # Convertir l'e-mail vide en None pour la base de données
    email_to_save = user.email if user.email else None

    hashed_password = get_password_hash(user.password)
    db_user = User(username=user.username, hashed_password=hashed_password, email=email_to_save)
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user

@app.post("/token", response_model=Token, summary="Obtenir un token d'accès (connexion)")
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), session: Session = Depends(get_session)):
    user = session.exec(select(User).where(User.username == form_data.username)).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nom d'utilisateur ou mot de passe incorrect",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username},
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

# Dependency to get current user
async def get_current_user(token: str = Depends(oauth2_scheme), session: Session = Depends(get_session)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Impossible de valider les identifiants",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception
    user = session.exec(select(User).where(User.username == token_data.username)).first()
    if user is None:
        raise credentials_exception
    return user

@app.get("/users/me", response_model=User, summary="Obtenir l'utilisateur actuel")
def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user

@app.post("/track/update", summary="Mettre à jour la position d'un véhicule")
async def update_vehicle_location(location_update: VehicleLocationUpdate, session: Session = Depends(get_session)):
    # Vérifier si le véhicule existe déjà
    vehicle_location = session.exec(select(VehicleLocation).where(VehicleLocation.vehicle_id == location_update.vehicle_id)).first()

    if vehicle_location:
        # Mettre à jour la position existante
        vehicle_location.latitude = location_update.latitude
        vehicle_location.longitude = location_update.longitude
        vehicle_location.timestamp = datetime.utcnow()
    else:
        # Créer une nouvelle entrée pour le véhicule
        vehicle_location = VehicleLocation(
            vehicle_id=location_update.vehicle_id,
            latitude=location_update.latitude,
            longitude=location_update.longitude
        )
    
    session.add(vehicle_location)
    session.commit()
    session.refresh(vehicle_location)
    # Diffuser la mise à jour de la position via WebSocket
    await manager.broadcast(json.dumps({
        "vehicle_id": vehicle_location.vehicle_id,
        "latitude": vehicle_location.latitude,
        "longitude": vehicle_location.longitude,
        "timestamp": str(vehicle_location.timestamp)
    }))
    return {"message": "Position du véhicule mise à jour", "vehicle_id": vehicle_location.vehicle_id, "latitude": vehicle_location.latitude, "longitude": vehicle_location.longitude}

@app.websocket("/ws/track/{vehicle_id}")
async def websocket_endpoint(websocket: WebSocket, vehicle_id: str):
    await manager.connect(websocket, vehicle_id)
    try:
        while True:
            # Keep connection alive, or handle messages from client if needed
            await websocket.receive_text() 
    except WebSocketDisconnect:
        manager.disconnect(vehicle_id)

# Pour lancer le serveur : uvicorn voyage:app --reload