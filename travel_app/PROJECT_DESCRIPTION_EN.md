# MonVoyage – Your Smart Travel Companion

## Project Description

"MonVoyage" is a mobile application developed with Flutter, designed to transform and simplify the intercity travel experience. It offers a comprehensive suite of features, including trip search and booking, real-time vehicle tracking, detailed travel information visualization (including distance traveled), and an integrated mobile payment process. Our mission is to solve real-world challenges related to travel planning and management, by providing an intuitive, visually appealing, and robust solution that encourages regular and repeated use.

## Google Maps Platform Usage and Experience

Although this project marks my first foray into application development with Google Maps Platform, it has been an exceptional learning opportunity to explore and leverage its powerful capabilities. I primarily used the **Maps SDK for Android** to integrate interactive and dynamic maps directly into the core of the application.

### Functionality and Scalability

*   **Dynamic Mapping:** The Maps SDK is the backbone of "MonVoyage," enabling the fluid and interactive display of routes. Clear polylines and custom markers for origin and destination points provide an instant visualization of the journey.
*   **Real-time Tracking:** The real-time tracking feature is designed to be highly scalable. By using a dynamic vehicle ID in the WebSocket URL, the application can adapt to any route or company, demonstrating the platform's flexibility in handling a continuous stream of location data.
*   **Accurate Distance Calculation:** The integration of distance calculation in kilometers between origin and destination cities, based on geographical coordinates, significantly enriches the information provided to the user, highlighting the platform's ability to deliver relevant and actionable geospatial data.
*   **Extension Potential (Places API):** A future extension is planned to integrate the **Places API**. This will allow users, once they arrive at their destination, to easily locate points of interest such as restaurants, hotels, or public places, transforming "MonVoyage" into an even more comprehensive travel guide.

### Purpose and Real-World Problem Solving

"MonVoyage" addresses a pressing need for simplification in intercity travel management. By centralizing trip search, booking, payment, and tracking in one place, the application eliminates complexity and information fragmentation. The clear visualization of routes and the ability to track vehicles in real-time provide invaluable peace of mind to travelers and their loved ones. The integration of mobile payment directly within the application significantly streamlines the booking process, offering a complete and frictionless experience, which is crucial for encouraging adoption and repeated use.

### Content and Visualization

The application stands out with a clean and modern user interface, where Google Maps are seamlessly and intuitively integrated. Distinct markers and blue polylines offer a clear and immediate visualization of routes. To draw the user's attention to crucial information, such as the "Agencies near you" section, I implemented a blinking text effect in red and bold. This creative approach aims to guide the user's eye to the most relevant information, thereby enhancing visual engagement.

### Execution and Technical Integrations

The project relies on robust technical integrations:
*   **`google_maps_flutter`:** For integrating interactive maps.
*   **`geolocator`:** For precise user location management and geographical distance calculation.
*   **`web_socket_channel`:** For implementing real-time vehicle tracking.
*   **Backend Integration:** The application interacts with a backend API (simulated locally for demonstration purposes) to retrieve trip and location data. This interaction demonstrates an understanding of data flows and the state management of a complex application.
*   **Mobile Payment Process:** The integration of a functional mobile payment process highlights the ability to manage secure transactional flows and provide a complete end-to-end user experience.

### User Experience

User experience is at the heart of "MonVoyage"'s design. The interface is crafted to be fluid and intuitive, with simplified navigation between trip search, payment, and confirmation pages. The clarity of presented information, the ease of selecting payment options, and the detailed trip summary contribute to a pleasant and frictionless user experience. The integration of maps and real-time tracking makes the application not only functional but also engaging and visually attractive, ensuring users feel informed and in control of their journey.

## Project Links

*   **GitHub Repository:** [**Insert your GitHub repository link here**]
*   **Demo Video:** [**Insert your YouTube video link here**]
*   **Web Application (if deployed):** [**Insert your Flutter Web application link here**]

---