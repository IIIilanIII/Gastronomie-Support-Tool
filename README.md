# Gastro-App Support-Tool
**Fullstack-Universitätsprojekt – Hochschule München**
(Kevin Wohlfahrt, Tilman Patzak, Simon Englhauser, Ilan Wiesner)

![Demo](https://github.com/user-attachments/assets/7c655981-5f8a-4384-8e96-89dd2cb921bd)

---

## Kurzbeschreibung
Dieses Support-Tool optimiert Gastronomie-Abläufe als eine digitale Schnittstelle zwischen Service und Küche. 

**Kernfunktionalität:**
Das Tool ermöglich die dynamische Verwaltung des Speisekarteninhalts,
sowie Kundenbestellungen für Bedienungen im Gastronomiebereich.

---

## Setup & Start

### 1. Backend (Spring Boot)
Voraussetzungen: 
Java version 21+ installiert haben
1. `cd backend`
2. `./gradlew bootRun` (Nutzt die konfigurierte Java-Toolchain)
### 2. Frontend
Voraussetzungen:
neueste Flutter version installiert haben und zugehöriges Dart
1. `cd frontend`
2. `flutter pub get`
3. `flutter run build_runner build --delete-conflicting-outputs` 
   *(Hinweis: Erforderlich für die Generierung von Mocks und Serialisierung)*
4. `flutter run`

Für Dokumentation bitte ins Wiki schauen :-) ![](https://github.com/IIIilanIII/Gastronomie-Support-Tool/wiki/Wiki)

---

*Entwickelt im Rahmen des Moduls Software Engineering I an der HM.*
