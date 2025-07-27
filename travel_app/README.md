# MonVoyage – Votre Compagnon de Voyage Intelligent

## Origine du Projet

L'idée de créer cette application est née du constat de la très grande désorganisation du secteur du voyage, de l'insécurité qui menace les voyageurs, et des longues files d'attente lors des réservations et du paiement des tickets dans mon pays. "MonVoyage" a pour but de résoudre ces problèmes en apportant une solution moderne, centralisée et sécurisée.

## Fonctionnalités

"MonVoyage" est une application mobile développée avec Flutter, conçue pour transformer et simplifier l'expérience de voyage interurbain. Elle offre une suite complète de fonctionnalités, incluant la recherche et la réservation de trajets, le suivi en temps réel de la position des véhicules, la visualisation détaillée des informations de voyage (y compris la distance parcourue), et un processus de paiement mobile intégré. Notre mission est de résoudre les défis réels liés à la planification et à la gestion des déplacements, en proposant une solution intuitive, visuellement attrayante et suffisamment robuste pour encourager une utilisation régulière et répétée.

*   **Recherche et Réservation Faciles :** Trouvez et réservez des trajets entre différentes villes, en filtrant par date.
*   **Cartographie Dynamique :** Le Maps SDK est l'épine dorsale de "MonVoyage", permettant l'affichage fluide et interactif des itinéraires. Les polylignes claires et les marqueurs personnalisés pour les points de départ et d'arrivée offrent une visualisation instantanée du trajet.
*   **Suivi en Temps Réel :** Suivez la position des bus et véhicules en temps réel sur la carte pour une meilleure tranquillité d'esprit pour les voyageurs et leurs proches. La fonctionnalité est conçue pour être hautement évolutive en utilisant un identifiant de véhicule dynamique.
*   **Calcul de Distance Précis :** L'intégration du calcul de la distance en kilomètres entre les villes de départ et d'arrivée enrichit considérablement les informations fournies à l'utilisateur.
*   **Paiement Mobile Sécurisé :** Un processus de paiement est directement intégré dans l'application pour une expérience de réservation complète et sans friction.

## Potentiel d'Évolution

Le projet est conçu pour être évolutif. Voici les prochaines étapes envisagées :

*   **Intégration de l'API Places :** Permettre aux utilisateurs, une fois arrivés à destination, de localiser facilement des points d'intérêt tels que des restaurants, des hôtels ou des lieux publics.
*   **Système de Notation :** Ajout d'une fonctionnalité permettant aux clients de noter les agences et compagnies de voyage directement depuis l'application, afin d'améliorer la qualité du service et d'aider les autres voyageurs à faire leur choix.

## Objectif et Résolution de Problèmes du Monde Réel

"MonVoyage" répond à un besoin criant de simplification dans la gestion des voyages interurbains. En centralisant la recherche de trajets, la réservation, le paiement et le suivi en un seul endroit, l'application élimine la complexité et la fragmentation des informations. La visualisation claire des trajets et la possibilité de suivre les véhicules en temps réel apportent une tranquillité d'esprit inestimable.

## Contenu et Visualisation

L'application se distingue par une interface utilisateur épurée et moderne. Les marqueurs distincts et les polylignes bleues offrent une visualisation claire des itinéraires. Pour capter l'attention sur des informations cruciales, comme la section "Agences de voyages proches de vous", un effet de texte clignotant a été implémenté pour guider l'œil de l'utilisateur et améliorer l'engagement visuel.

## Exécution et Intégrations Techniques

Le projet s'appuie sur des intégrations techniques robustes :
*   **`google_maps_flutter` :** Pour l'intégration des cartes interactives.
*   **`geolocator` :** Pour la gestion précise de la localisation de l'utilisateur.
*   **`web_socket_channel` :** Pour la mise en œuvre du suivi des véhicules en temps réel.
*   **Intégration Backend :** L'application interagit avec une API backend FastAPI (Python) pour récupérer les données de trajet et de localisation.
*   **Processus de Paiement :** L'intégration d'un processus de paiement mobile fonctionnel met en évidence la capacité à gérer des flux transactionnels sécurisés.

## Expérience Utilisateur

L'expérience utilisateur est au cœur de la conception de "MonVoyage". L'interface est conçue pour être fluide et intuitive, avec une navigation simplifiée. La clarté des informations présentées et la facilité des processus contribuent à une expérience agréable et sans friction.

## Liens du Projet

*   **Dépôt GitHub :** [**Insérer le lien de votre dépôt GitHub ici**]
*   **Vidéo de Démonstration :** [**Insérer le lien de votre vidéo YouTube ici**]
*   **Application Web (si déployée) :** [**Insérer le lien de votre application Flutter Web ici**]