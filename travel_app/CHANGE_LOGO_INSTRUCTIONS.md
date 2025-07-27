# Procédure pour Modifier le Logo de l'Application "MonVoyage"

Cette procédure vous guidera à travers les étapes pour changer le logo de votre application Flutter, "MonVoyage". La méthode recommandée utilise le package `flutter_launcher_icons` pour simplifier le processus.

## Étape 1 : Préparer Votre Logo

Avant de commencer, assurez-vous d'avoir votre nouveau logo prêt. Il est préférable d'avoir une image de haute résolution (par exemple, 1024x1024 pixels ou plus) au format PNG avec un fond transparent si désiré. Le package `flutter_launcher_icons` redimensionnera automatiquement votre image pour toutes les plateformes.

## Étape 2 : Ajouter le Package `flutter_launcher_icons`

1.  Ouvrez le fichier `pubspec.yaml` de votre projet.
2.  Ajoutez `flutter_launcher_icons` sous la section `dev_dependencies` :

    ```yaml
    dev_dependencies:
      flutter_test:
        sdk: flutter
      flutter_lints: ^5.0.0
      flutter_launcher_icons: "^0.13.1" # Vérifiez la dernière version sur pub.dev
    ```

3.  Enregistrez le fichier `pubspec.yaml`.
4.  Exécutez la commande suivante dans votre terminal pour télécharger le package :

    ```bash
    flutter pub get
    ```

## Étape 3 : Configurer le Package `flutter_launcher_icons`

1.  Dans le même fichier `pubspec.yaml`, ajoutez une nouvelle section `flutter_launcher_icons` au même niveau que `flutter` et `dev_dependencies` :

    ```yaml
    flutter:
      uses-material-design: true
      assets:
        - assets/data/database.json

    flutter_launcher_icons:
      android: true
      ios: true
      image_path: "assets/images/your_logo.png" # Remplacez par le chemin réel de votre logo
      min_sdk_android: 21 # La version minimale d'Android supportée par votre application
      # adaptive_icon_background: "#FFFFFF" # Optionnel: couleur de fond pour les icônes adaptatives Android
      # adaptive_icon_foreground: "assets/images/your_logo_foreground.png" # Optionnel: image de premier plan pour les icônes adaptatives Android
    ```

    *   **`android: true`** et **`ios: true`** indiquent que vous voulez générer des icônes pour ces plateformes.
    *   **`image_path`** doit pointer vers le fichier PNG de votre logo. Créez un dossier `assets/images` si vous ne l'avez pas déjà et placez-y votre logo.
    *   **`min_sdk_android`** doit correspondre à la `minSdkVersion` définie dans votre fichier `android/app/build.gradle`.
    *   Les options `adaptive_icon_background` et `adaptive_icon_foreground` sont pour les icônes adaptatives d'Android (Android 8.0 Oreo et plus). Si vous les utilisez, vous devrez fournir une image de premier plan séparée et/ou une couleur de fond.

2.  Enregistrez le fichier `pubspec.yaml`.

## Étape 4 : Générer les Icônes

Exécutez la commande suivante dans votre terminal :

```bash
flutter pub run flutter_launcher_icons:main
```

Cette commande va générer toutes les icônes nécessaires et les placer automatiquement dans les répertoires spécifiques à Android et iOS de votre projet.

## Étape 5 : Nettoyer et Reconstruire le Projet

Après avoir généré les icônes, il est crucial de nettoyer votre projet et de le reconstruire pour que les nouvelles icônes soient prises en compte.

1.  Nettoyez le projet :

    ```bash
    flutter clean
    ```

2.  Téléchargez les dépendances (si ce n'est pas déjà fait ou si vous avez des doutes) :

    ```bash
    flutter pub get
    ```

3.  Lancez votre application :

    ```bash
    flutter run
    ```

Votre application devrait maintenant afficher le nouveau logo sur l'écran d'accueil de votre appareil ou émulateur.

## Dépannage (si le logo ne change pas)

*   Assurez-vous que le `image_path` dans `pubspec.yaml` est correct et que le fichier image existe à cet emplacement.
*   Vérifiez que `min_sdk_android` dans `pubspec.yaml` correspond à celui de `android/app/build.gradle`.
*   Si vous avez des problèmes persistants, essayez de désinstaller complètement l'application de votre appareil/émulateur avant de relancer `flutter run`.

---