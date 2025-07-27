# MonVoyage – Votre Compagnon de Voyage Intelligent

## Description du Projet

"MonVoyage" est une application mobile développée avec Flutter, conçue pour transformer et simplifier l'expérience de voyage interurbain. Elle offre une suite complète de fonctionnalités, incluant la recherche et la réservation de trajets, le suivi en temps réel de la position des véhicules, la visualisation détaillée des informations de voyage (y compris la distance parcourue), et un processus de paiement mobile intégré. Notre mission est de résoudre les défis réels liés à la planification et à la gestion des déplacements, en proposant une solution intuitive, visuellement attrayante et suffisamment robuste pour encourager une utilisation régulière et répétée.

## Utilisation de Google Maps Platform et Expérience

Bien que ce projet marque ma première incursion dans le développement d'applications avec Google Maps Platform, il a été une opportunité d'apprentissage exceptionnelle pour explorer et exploiter ses puissantes capacités. J'ai principalement utilisé le **Maps SDK for Android** pour intégrer des cartes interactives et dynamiques directement au cœur de l'application.

### Fonctionnalité et Évolutivité

*   **Cartographie Dynamique :** Le Maps SDK est l'épine dorsale de "MonVoyage", permettant l'affichage fluide et interactif des itinéraires. Les polylignes claires et les marqueurs personnalisés pour les points de départ et d'arrivée offrent une visualisation instantanée du trajet.
*   **Suivi en Temps Réel :** La fonctionnalité de suivi en temps réel est conçue pour être hautement évolutive. En utilisant un identifiant de véhicule dynamique dans l'URL du WebSocket, l'application peut s'adapter à n'importe quel trajet ou compagnie, démontrant la flexibilité de la plateforme à gérer un flux continu de données de localisation.
*   **Calcul de Distance Précis :** L'intégration du calcul de la distance en kilomètres entre les villes de départ et d'arrivée, basée sur les coordonnées géographiques, enrichit considérablement les informations fournies à l'utilisateur, soulignant la capacité de la plateforme à fournir des données géospatiales pertinentes et exploitables.
*   **Potentiel d'Extension (API Places) :** Une future extension est prévue pour intégrer l'**API Places**. Cela permettra aux utilisateurs, une fois arrivés à destination, de localiser facilement des points d'intérêt tels que des restaurants, des hôtels ou des lieux publics, transformant "MonVoyage" en un guide de voyage encore plus complet.

### Objectif et Résolution de Problèmes du Monde Réel

"MonVoyage" répond à un besoin criant de simplification dans la gestion des voyages interurbains. En centralisant la recherche de trajets, la réservation, le paiement et le suivi en un seul endroit, l'application élimine la complexité et la fragmentation des informations. La visualisation claire des trajets et la possibilité de suivre les véhicules en temps réel apportent une tranquillité d'esprit inestimable aux voyageurs et à leurs proches. L'intégration du paiement mobile directement dans l'application simplifie considérablement le processus de réservation, offrant une expérience complète et sans friction, ce qui est crucial pour encourager l'adoption et l'utilisation répétée.

### Contenu et Visualisation

L'application se distingue par une interface utilisateur épurée et moderne, où les cartes Google Maps sont intégrées de manière fluide et intuitive. Les marqueurs distincts et les polylignes bleues offrent une visualisation claire et immédiate des itinéraires. Pour capter l'attention de l'utilisateur sur des informations cruciales, comme la section "Agences de voyages proches de vous", j'ai implémenté un effet de texte clignotant en rouge et en gras. Cette approche créative vise à guider l'œil de l'utilisateur vers les informations les plus pertinentes, améliorant ainsi l'engagement visuel.

### Exécution et Intégrations Techniques

Le projet s'appuie sur des intégrations techniques robustes :
*   **`google_maps_flutter` :** Pour l'intégration des cartes interactives.
*   **`geolocator` :** Pour la gestion précise de la localisation de l'utilisateur et le calcul des distances géographiques.
*   **`web_socket_channel` :** Pour la mise en œuvre du suivi des véhicules en temps réel.
*   **Intégration Backend :** L'application interagit avec une API backend (simulée localement pour la démonstration) pour récupérer les données de trajet et de localisation. Cette interaction démontre une compréhension des flux de données et de la gestion des états d'une application complexe.
*   **Processus de Paiement :** L'intégration d'un processus de paiement mobile fonctionnel met en évidence la capacité à gérer des flux transactionnels sécurisés et à offrir une expérience utilisateur complète de bout en bout.

### Expérience Utilisateur

L'expérience utilisateur est au cœur de la conception de "MonVoyage". L'interface est conçue pour être fluide et intuitive, avec une navigation simplifiée entre la recherche de trajets, la page de paiement et la page de confirmation. La clarté des informations présentées, la facilité de sélection des options de paiement, et le résumé détaillé du voyage contribuent à une expérience utilisateur agréable et sans friction. L'intégration des cartes et du suivi en temps réel rend l'application non seulement fonctionnelle mais aussi engageante et visuellement attrayante, garantissant que les utilisateurs se sentent informés et en contrôle de leur voyage.

## Liens du Projet

*   **Dépôt GitHub :** [**Insérer le lien de votre dépôt GitHub ici**]
*   **Vidéo de Démonstration :** [**Insérer le lien de votre vidéo YouTube ici**]
*   **Application Web (si déployée) :** [**Insérer le lien de votre application Flutter Web ici**]

---