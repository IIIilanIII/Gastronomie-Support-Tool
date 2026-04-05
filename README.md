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
Voraussetzungen: Java version 17+ installiert haben
1. `cd backend`
2. `./gradlew bootRun` (Nutzt die konfigurierte Java-Toolchain)
### 2. Frontend
1. `cd frontend`
2. `flutter pub get`
3. `flutter run build_runner build --delete-conflicting-outputs` 
   *(Hinweis: Erforderlich für die Generierung von Mocks und Serialisierung)*
4. `flutter run`

---

## Dokumentation

## Domänen-/Datenmodell
<img width="581" height="1123" alt="Domänen-_Datenmodell" src="https://github.com/user-attachments/assets/890eda31-47ac-435f-b823-ec90d8cb48b7" />

## Use-Case-Diagramm
<img width="968" height="821" alt="image" src="https://github.com/user-attachments/assets/ff16a84c-4434-4594-a46b-13f18e959644" />

## Aktivitäts-Diagramm
<img width="372" height="1201" alt="AKTIVITÄTSDIAGRAMM_SE drawio" src="https://github.com/user-attachments/assets/6a0baadc-1a3b-4903-aedf-23fcee91e079" />

## Zustands-Diagramm
<img width="365" height="616" alt="ZUSTANDSDIAGRAMM_SE drawio" src="https://github.com/user-attachments/assets/ae39095f-3424-4b70-8607-5f7eb15c0a0a" />

## Definitionen

### Definition of ready

- Anforderungen sind klar und elementar definiert und verständlich 
- Akzeptanzkriterien für alle klar
- Umsetzungsumfang/Einarbeitungszeit für einen Sprint realistisch
- Story basiert nicht auf unfertige oder ungeplante Storys, kann also umgesetzt werden.

### Definition of done

- Test Coverage alle Klassen/Dateien beträgt mindestens 85%
- Anforderung wurde umgesetzt. Abweichungen wurden vom Team akzeptiert.
- Akzeptanzkriterien sind erfüllt 
- Mergerequest wurde mindestens von einem weiterem Maintainer approved

---
*Entwickelt im Rahmen des Moduls Software Engineering I an der HM.*
