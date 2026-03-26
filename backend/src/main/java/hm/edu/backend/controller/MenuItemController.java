package hm.edu.backend.controller;

import hm.edu.backend.model.MenuItem;
import hm.edu.backend.services.BarOrderService;
import hm.edu.backend.services.MenuItemService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

/**
 * REST-Controller fuer CRUD-Operationen auf MenuItems inklusive Filter nach Archiv-Status und Version.
 */
@RestController
@Validated
public class MenuItemController {
    @Autowired
    private MenuItemService menuItemService;
    @Autowired
    private BarOrderService barOrderService;

    /**
     * Liefert alle MenuItems; optional gefiltert nach Archiv-Flag oder Version.
     * @param archived optionaler Archiv-Parameter (?archived=[true/false])
     * @param version optionale Versionsnummer (?version=...)
     * @return Liste passender MenuItems
     * @throws ResponseStatusException  405, wenn gleichzeitig nach archived und version gefiltert wird
     *                                  422, wenn version/ archived ungültig ist
     */
    @GetMapping("/menuItems")
    ResponseEntity<List<MenuItem>> allMenuItems(@RequestParam(required = false) String archived, @RequestParam(required = false) Integer version) {
        if (version != null && archived != null) {
            throw new ResponseStatusException(HttpStatus.METHOD_NOT_ALLOWED, "Gleichzeitiges filtern nach archived und version nicht unterstützt");
        }

        // Version filter
        if (version != null) {
            if (version < 1) throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "Version must be greater than 0");

            return ResponseEntity.ok(menuItemService.getAllMenuItemsByVersion(version));
        }

        // Archived filter
        if (archived != null) {
            if (archived.isBlank() || (!archived.equalsIgnoreCase("true") && !archived.equalsIgnoreCase("false"))) {
                // kein valider boolean
                throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "Archived must be valid boolean");
            }

            boolean archivedFlag = Boolean.parseBoolean(archived);

            return ResponseEntity.ok(menuItemService.getAllMenuItemsByArchived(archivedFlag));
        }

        // kein filter
        return ResponseEntity.ok(menuItemService.getAllMenuItems());
    }

    /**
     * Legt ein neues MenuItem an.
     * @param newMenuItem zu speicherndes MenuItem
     * @return 204 No Content bei Erfolg
     * @throws ResponseStatusException  403, wenn ID vorhanden ist oder Daten ungültig sind
     */
    @PostMapping("/menuItem")
    ResponseEntity<Void> newMenuItem(@Valid @RequestBody MenuItem newMenuItem) {
        if (newMenuItem.getId() != null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "New menuItem id must be null");
        }
        if (newMenuItem.isArchived()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "When creating menuItems, archived cannot be true");
        }
        if (newMenuItem.getVersion() != 1) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "When creating menuItems, version must be 1");
        }

        // entferne führende und nachfolgende Leerzeichen
        newMenuItem.setName(newMenuItem.getName().trim());
        newMenuItem.setDescription(newMenuItem.getDescription().trim());

        menuItemService.saveMenuItem(newMenuItem);
        return ResponseEntity.noContent().build();
    }

    /**
     * Liefert ein MenuItem per ID.
     * @param id ID des MenuItems
     * @return gefundenes MenuItem
     * @throws ResponseStatusException  404, wenn MenuItem nicht existiert,
     *                                  422, wenn ID ungültig ist
     */
    @GetMapping("/menuItem/{id}")
    ResponseEntity<MenuItem> getMenuItem(@PathVariable Long id) {
        checkId(id);
        // kein menuItem mit der ID -> exception wird bereits im Service ausgelöst
        return ResponseEntity.ok(menuItemService.getMenuItemById(id));
    }

    /**
     * Aktualisiert ein MenuItem, sofern es nicht archiviert ist.
     * @param updatedMenuItem MenuItem mit neuen Werten
     * @return 204 No Content bei Erfolg
     * @throws ResponseStatusException  403, wenn MenuItem archiviert ist,
     *                                  404, wenn MenuItem nicht existiert,
     *                                  422, wenn ID ungültig ist
     */
    @PutMapping("/menuItem")
    ResponseEntity<Void> updateMenuItem(@Valid @RequestBody MenuItem updatedMenuItem) {
        checkId(updatedMenuItem.getId());
        // 1. Stelle sicher, dass das MenuItem mit der gegebenen ID existiert; sonst -> 404 Not Found
        MenuItem existing = menuItemService.getMenuItemById(updatedMenuItem.getId());

        // 2. Wenn ein menuItem mit der gegebenen ID existiert: stelle sicher, dass es nicht archiviert ist
        if (existing.isArchived()) {
            // archiviertes MenuItem kann nicht aktualisiert werden
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "MenuItem is archived");
        }

        // Führende und nachfolgende Leerzeichen entfernen
        updatedMenuItem.setName(updatedMenuItem.getName().trim());
        updatedMenuItem.setDescription(updatedMenuItem.getDescription().trim());

        // Prüfe, ob sich beim menuItem etwas geändert hat; wenn nicht, tue nichts
        if (updatedMenuItem.equals(existing)) {
            return ResponseEntity.noContent().build();
        }

        // 3. Wenn das menuItem existiert, nicht archiviert ist und sich etwas geändert hat: update durchführen
        menuItemService.updateMenuItem(updatedMenuItem);

        return ResponseEntity.noContent().build();
    }

    /**
     * Löscht ein MenuItem per ID.
     * @param id ID des zu löschenden MenuItems
     * @return 204 No Content bei Erfolg
     * @throws ResponseStatusException  403, wenn MenuItem archiviert ist oder in einer BarOrder enthalten ist,
     *                                  422, wenn ID ungültig ist
     */
    @DeleteMapping("/menuItem/{id}")
    ResponseEntity<Void> deleteMenuItem(@PathVariable Long id) {
        checkId(id);

        try {
            // 1. menuItem aus DB holen und prüfen, dass es nicht archiviert ist
            MenuItem menuItem = menuItemService.getMenuItemById(id);
            if (menuItem.isArchived()) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cannot delete archived menuItems");
            }

            // 2. Prüfen, dass das menuItem in keiner BarOrder enthalten ist
            // allBarOrders -> stream -> filter nach barOrders, die das menuItem enthalten -> findFirst + ifPresent: wenn eines existiert -> exception
            barOrderService.getAllBarOrders().stream()
                    .filter(barOrder -> barOrder.containsMenuItem(id))
                    .findFirst()
                    .ifPresent(barOrder -> {
                        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cannot delete menuItems in open barOrders");
                    });

            // 3. Löschen ist möglich -> im service aufrufen
            menuItemService.deleteMenuItemById(id);

        } catch (ResponseStatusException e) {
            // wenn menuItem nicht existiert -> status NOT_FOUND -> still ignorieren, da eh nicht gelöscht werden kann
            // alle anderen exceptions durchreichen
            if (e.getStatusCode() != HttpStatus.NOT_FOUND) {
                throw e;
            }
        }

        return ResponseEntity.noContent().build();
    }

    /**
     * Prüft, ob die ID gültig ist (>0).
     * @param id id to check
     * @throws ResponseStatusException 422, wenn ID ungültig ist
     */
    private static void checkId(Long id) throws ResponseStatusException {
        if (id == null || id <= 0) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "ID must be > 0");
        }
    }



}