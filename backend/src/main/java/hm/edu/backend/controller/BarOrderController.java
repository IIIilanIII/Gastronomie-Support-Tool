package hm.edu.backend.controller;

import hm.edu.backend.model.BarOrder;
import hm.edu.backend.model.BarOrderItem;
import hm.edu.backend.model.BarTable;
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
 * * REST-Controller für CRUD-Operationen auf Bestellungen (BarOrders).
 */
@RestController
@Validated
public class BarOrderController {

    @Autowired
    private BarOrderService barOrderService;
    @Autowired
    private MenuItemService menuItemService;

    /**
     * Liefert alle Bestellungen.
     * @return Liste aller Bestellungen
     */
    @GetMapping("/barOrders")
    ResponseEntity<List<BarOrder>> allBarOrders() {
        return ResponseEntity.ok(barOrderService.getAllBarOrders());
    }

    /**
     * Erstellt eine neue Bestellung.
     * @param newBarOrder die neue Bestellung
     * @return 204 No Content bei Erfolg
     * @throws ResponseStatusException  403, wenn ID in neuer BarOrder vorhanden ist oder Daten ungültig sind,
     *                                  404, wenn in BarOrder enthaltenes MenuItem nicht in DB existiert,
     *                                  422, wenn BarTable nicht existiert oder ID im falschen Wertebereich liegt,
     *                                       wenn MenuItem in BarOrder archiviert ist oder nicht existiert,
     *                                       wenn Menge eines BarOrderItems ≤ 0 ist
     */
    @PostMapping("/barOrder")
    ResponseEntity<Void> newBarOrder(@Valid @RequestBody BarOrder newBarOrder) throws ResponseStatusException {
        // Prüfe, dass ID nicht im Objekt vorhanden ist (wird im Repository zugewiesen)
        if (newBarOrder.getId() != null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "New BarOrder ID must be null");
        }

        // Prüfe, dass BarTable existiert und ID im richtigen Wertebereich liegt
        checkBarTable(newBarOrder.getBarTable());

        // Prüfe, dass BarOrder nicht archiviert ist
        checkArchived(newBarOrder);

        // Prüfe für jedes MenuItem, dass es nicht null ist und nicht archiviert ist
        for (MenuItem item : newBarOrder.getItems().stream().map(BarOrderItem::getMenuItem).toList()) {
            // das tatsächliche MenuItem aus der DB holen
            MenuItem menuItem = menuItemService.getMenuItemById(item.getId());
            if (menuItem.isArchived()) {
                // menuItem == null hier nicht benötigt, da getMenuItemById() schon Exception (404) werfen würde
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Given MenuItem is archived");
            }
        }

        // Speichern im Service aufrufen
        barOrderService.saveBarOrder(newBarOrder);
        return ResponseEntity.noContent().build();
    }

    /**
     * Liefert eine Bestellung per ID.
     * @param id die ID der Bestellung
     * @return gefundene Bestellung
     * @throws ResponseStatusException  404, wenn BarOrder nicht existiert,
     *                                  422, wenn ID ungültig ist
     */
    @GetMapping("/barOrder/{id}")
    ResponseEntity<BarOrder> getBarOrder(@PathVariable Long id) throws ResponseStatusException {
        // Prüfe, dass ID im richtigen Wertebereich liegt
        checkId(id);
        return ResponseEntity.ok(barOrderService.getBarOrderById(id));
    }

    /**
     * Aktualisiert eine bestehende Bestellung.
     * @param updatedBarOrder die aktualisierte Bestellung
     * @return 204 No Content bei Erfolg
     * @throws ResponseStatusException  403, wenn BarOrder archiviert ist,
     *                                  404, wenn BarOrder nicht existiert,
     *                                  422, wenn ID/ BarTable ungültig ist
     */
    @PutMapping("/barOrder")
    ResponseEntity<Void> updateBarOrder(@Valid @RequestBody BarOrder updatedBarOrder) {
        // Prüfe, dass ID im richtigen Wertebereich liegt
        checkId(updatedBarOrder.getId());
        // Prüfe, dass BarTable existiert und ID im richtigen Wertebereich liegt
        checkBarTable(updatedBarOrder.getBarTable());
        // Prüfe, ob BarOrder existiert
        BarOrder existing = barOrderService.getBarOrderById(updatedBarOrder.getId());
        // Prüfe, dass BarOrder nicht archiviert ist
        checkArchived(existing);

        // wenn keine Änderungen, passiert nichts
        if (updatedBarOrder.equals(existing)) {
            return ResponseEntity.noContent().build();
        }

        // Update im service aufrufen
        barOrderService.updateBarOrder(updatedBarOrder);
        return ResponseEntity.noContent().build();
    }

    /**
     * Eine Bestellung archivieren.
     * @param id die ID der Bestellung
     * @return 204 No Content bei Erfolg
     * @throws ResponseStatusException  403, wenn BarOrder archiviert ist,
     *                                  404, wenn BarOrder nicht existiert,
     *                                  422, wenn ID ungültig ist
     */
    @PutMapping("/barOrder/{id}/archive")
    ResponseEntity<Void> archiveBarOrder(@PathVariable Long id) throws ResponseStatusException {
        //Prüfe, dass ID im richtigen Wertebereich liegt
        checkId(id);
        // Prüfe, ob BarOrder existiert
        BarOrder existing = barOrderService.getBarOrderById(id);
        // Prüfe, dass BarOrder nicht archiviert ist
        checkArchived(existing);
        // Archive im service aufrufen
        barOrderService.archiveBarOrder(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Löscht eine Bestellung per ID.
     * @param id die ID der zu löschenden Bestellung
     * @return 204 No Content bei Erfolg oder wenn Bestellung nicht existiert
     * @throws ResponseStatusException  403, wenn BarOrder archiviert ist,
     *                                  422, wenn ID ungültig ist
     */
    @DeleteMapping("/barOrder/{id}")
    ResponseEntity<Void> deleteBarOrder(@PathVariable Long id) {
        //Prüfe, dass ID im richtigen Wertebereich liegt
        checkId(id);
        // Prüfe, ob BarOrder existiert
        try {
            // Bestehende BarOrder holen
            BarOrder existing = barOrderService.getBarOrderById(id);
            // Prüfe, dass BarOrder nicht archiviert ist
            checkArchived(existing);
            // Delete im service aufrufen
            barOrderService.deleteBarOrderById(id);
        } catch (ResponseStatusException e) {
            // wenn BarOrder nicht existiert → still ignorieren, da eh nicht gelöscht werden kann
            // restliche exceptions durchreichen
            if (e.getStatusCode() != HttpStatus.NOT_FOUND) {
                throw e;
            }
        }

        return ResponseEntity.noContent().build();
    }

    /**
     * Prüft, ob die ID gültig ist (>0).
     * @param id die zu prüfende ID
     * @throws ResponseStatusException 422, wenn ID ungültig ist
     */
    private static void checkId(Long id) throws ResponseStatusException {
        if (id == null || id <= 0) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "ID must be > 0");
        }
    }

    /**
     * Prüft, ob der BarTable gültig ist (nicht null, ID >0).
     * @param barTable zu prüfender BarTable
     * @throws ResponseStatusException 422, wenn BarTable ungültig ist
     */
    private static void checkBarTable(BarTable barTable) throws ResponseStatusException {
        if (barTable.getId() <= 0) {
            // check barTable == null hier nicht benötigt, da @NotNull in BarOrder schon automatisch prüft
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "BarTable ID must be > 0");
        }
    }

    /**
     * Prüft, ob die BarOrder archiviert ist.
     * @param barOrder zu prüfende BarOrder
     * @throws ResponseStatusException 403, wenn BarOrder archiviert ist
     */
    private static void checkArchived(BarOrder barOrder) throws ResponseStatusException {
        if (barOrder.isArchived()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "BarOrder is archived and cannot be updated");
        }
    }
}
