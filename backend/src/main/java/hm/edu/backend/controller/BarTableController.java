package hm.edu.backend.controller;

import hm.edu.backend.services.BarTableService;
import hm.edu.backend.model.BarTable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
/**
 * REST-Controller fuer CRUD-Operationen auf BarTables.
 */
@RestController
public class BarTableController {

    @Autowired
    private BarTableService barTableService;

    /**
     * Liefert alle Tische.
     * @return Liste aller Tische
     */
    @GetMapping("/barTables")
    ResponseEntity<List<BarTable>> allBarTables() {
        return ResponseEntity.ok(barTableService.getAllBarTables());
    }

    /**
     * Liefert einen Tisch mit der gegebenen ID.
     * @param id die ID des Tisches
     * @return der gesuchte Tisch
     * @throws ResponseStatusException  404, wenn der Tisch nicht existiert,
     *                                  422, wenn die ID ungültig ist
     */
    @GetMapping("/barTable/{id}")
    ResponseEntity<BarTable> getBarTable(@PathVariable Long id) {
        // ID == null wird von Spring automatisch VOR dem Controller abgefangen
        if (id < 1) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "ID must be greater than 0");
        }

        try {
            return ResponseEntity.ok(barTableService.getBarTableById(id));
        } catch (RuntimeException e) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Bar Table does not exist");
        }
    }
}

