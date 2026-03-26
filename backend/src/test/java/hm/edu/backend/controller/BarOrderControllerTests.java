package hm.edu.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import hm.edu.backend.model.BarOrder;
import hm.edu.backend.model.BarOrderItem;
import hm.edu.backend.model.BarTable;
import hm.edu.backend.model.MenuItem;
import hm.edu.backend.services.BarOrderService;
import hm.edu.backend.services.MenuItemService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.IntStream;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(SpringExtension.class)
@WebMvcTest(BarOrderController.class)
@AutoConfigureMockMvc

/**
 * Testklasse fuer den BarOrderController
 */
public class BarOrderControllerTests {
    // JSON-Mapper um erstellte Objekte in JSON-Strings zu konvertieren
    // wichtig fuer POST- und PUT-Requests
    private final ObjectMapper mapper = new ObjectMapper();

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private BarOrderService barOrderService;

    @MockitoBean
    private MenuItemService menuItemService;

    // ########--HILFSMETHODEN--########################################################

    /**
     * Erstellt eine BarTable mit der gegebenen ID.
     * @param id
     * @return BarTable mit der gegebenen ID
     */
    static BarTable createTable(long id) {
        return new BarTable(id);
    }

    /**
     * Erstellt n BarOrderItems fuer die gegebene BarOrder.
     * @param order BarOrder
     * @param n Anzahl der zu erstellenden BarOrderItems
     * @return Liste der erstellten BarOrderItems
     */
    static List<BarOrderItem> createItems(BarOrder order, int n) {
        return IntStream.rangeClosed(1, n).mapToObj(i -> {
            MenuItem item = new MenuItem(i, "Item " + i, "Desc " + i, i, i, false);
            return new BarOrderItem(order, item, i);
        }).toList();
    }

    /**
     * Erstellt n BarOrders mit jeweils 2*n BarOrderItems.
     * @param n Anzahl der zu erstellenden BarOrders
     * @return Liste der erstellten BarOrders
     */
    static List<BarOrder> createOrders(int n) {
        return IntStream.rangeClosed(1, n).mapToObj(i -> {
            BarOrder order = new BarOrder(i, createTable(i), List.of());
            List<BarOrderItem> items = createItems(order, i * 2);
            order.setItems(items);
            return order;
        }).toList();
    }
    /**
     * Erstellt n BarOrders mit jeweils 2*n BarOrderItems.
     * @param n Anzahl der zu erstellenden BarOrders
     * @return Liste der erstellten BarOrders
     */
    static List<BarOrder> createOrdersNoId(int n) {
        return IntStream.rangeClosed(1, n).mapToObj(i -> {
            BarOrder order = new BarOrder(createTable(i), List.of());
            List<BarOrderItem> items = createItems(order, i * 2);
            order.setItems(items);
            return order;
        }).toList();
    }

    // ########-GET /barOrders-########################################################
    /**
     * getAllBarOrders: barOrders existieren.
     * Erwartet: 200 OK mit Liste der BarOrders.
     */
    @Test
    void testAllBarOrders1() throws Exception {
        // Testvorbereitung: Erstellen von 3 BarOrders
        List<BarOrder> orders = createOrders(3);
        // Mock-Verhalten definieren
        when(barOrderService.getAllBarOrders()).thenReturn(orders);
        // Ausfuehren des GET-Requests und Ueberpruefen der Antwort
        mockMvc.perform(get("/barOrders").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3));
        // Call-Verifizierung
        verify(barOrderService).getAllBarOrders();
    }

    /**
     * getAllBarOrders: keine BarOrders vorhanden.
     * Erwartet: 200 OK mit leerer Liste.
     */
    @Test
    void testAllBarOrders2() throws Exception {
        // Mock-Verhalten definieren
        when(barOrderService.getAllBarOrders()).thenReturn(List.of());
        // Ausfuehren des GET-Requests und Ueberpruefen der Antwort
        mockMvc.perform(get("/barOrders").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
        // Call-Verifizierung
        verify(barOrderService).getAllBarOrders();
    }

    // ########-GET /barOrder/{id}-########################################################
    /**
     * getBarOrder: BarOrder existiert.
     * Erwartet: 200 OK mit Liste von barOrders (1 stück)
     */
    @Test
    void testGetBarOrder1() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder
        BarOrder order = createOrders(1).get(0);
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(1L)).thenReturn(order);
        // Ausfuehren des GET-Requests und Ueberpruefen der Antwort
        mockMvc.perform(get("/barOrder/{id}", 1L).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1));
        // Call-Verifizierung
        verify(barOrderService).getBarOrderById(1L);
    }

    /**
     * getBarOrder: BarOrder existiert nicht.
     * Erwartet: 404 Not Found.
     */
    @Test
    void testGetBarOrder2() throws Exception {
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(99L)).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "BarOrder does not exist"));
        // Ausführen des GET-Requests und überprüfen der Antwort
        mockMvc.perform(get("/barOrder/{id}", 99L).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
        // Call-Verifizierung
        verify(barOrderService).getBarOrderById(99L);
    }

    /**
     * getBarOrder: Ungültige ID (0).
     * Erwartet: 422 Unprocessable entity
     */
    @Test
    void testGetBarOrder3() throws Exception {
        // Ausfuehren des GET-Requests und Ueberpruefen der Antwort
        mockMvc.perform(get("/barOrder/{id}", 0L).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnprocessableEntity());
        // Call-Verifizierung (in diesem Fall sollte der Service nicht aufgerufen werden)
        verify(barOrderService, never()).getBarOrderById(anyLong());
    }

    /**
     * getBarOrder: Bestellung existiert nicht.
     * Erwartet: 404 Not Found.
     */
    @Test
    void testGetBarOrder4() throws Exception {
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(1L)).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "BarOrder does not exist"));

        // Ausführen des GET-Requests und Ueberpruefen der Antwort
        mockMvc.perform(get("/barOrder/{id}", 1L).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
        // Call-Verifizierung
        verify(barOrderService).getBarOrderById(1L);
    }

    // ########-POST /barOrder-########################################################
    /**
     * newBarOrder: Gültige BarOrder.
     * Erwartet: 204 No Content.
     */
    @Test
    void testNewBarOrder1() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder
        BarOrder order = createOrdersNoId(1).getFirst();
        String json = mapper.writeValueAsString(order);

        for (BarOrderItem item : order.getItems()) {
            MenuItem menuItem = item.getMenuItem();
            when(menuItemService.getMenuItemById(menuItem.getId())).thenReturn(menuItem);
        }

        // Ausfuehren des POST-Requests und Ueberpruefen der Antwort
        mockMvc.perform(post("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isNoContent());
        // Call-Verifizierung (prüfen, dass eine BarOrder gespeichert wurde)
        verify(barOrderService).saveBarOrder(any(BarOrder.class));
    }

    /**
     * newBarOrder: Ungültige BarOrder (null BarTable).
     * Erwartet: 400 Bad Request.
     */
    @Test
    void testNewBarOrder2() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit null BarTable
        BarOrder invalidOrder = new BarOrder(1L, null, List.of());
        String json = mapper.writeValueAsString(invalidOrder);
        // Ausfuehren des POST-Requests und Ueberpruefen der Antwort
        mockMvc.perform(post("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isBadRequest());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).saveBarOrder(any(BarOrder.class));
    }

    /**
     * newBarOrder: Ungültige BarOrder (ID 0).
     * Erwartet: 403 Forbidden
     */
    @Test
    void testNewBarOrder3() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit ID 0
        BarOrder invalidOrder = new BarOrder(0L, createTable(1), List.of());
        String json = mapper.writeValueAsString(invalidOrder);
        // Ausfuehren des POST-Requests und Ueberpruefen der Antwort
        mockMvc.perform(post("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isForbidden());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).saveBarOrder(any(BarOrder.class));
    }

    /**
     * newBarOrder: Ungültige BarOrder (BarTable ID 0).
     * Erwartet: 422 Unprocessable Entity
     */
    @Test
    void testNewBarOrder4() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit BarTable ID 0
        BarOrder invalidOrder = new BarOrder(new BarTable(0L), List.of());
        String json = mapper.writeValueAsString(invalidOrder);
        // Ausfuehren des POST-Requests und Ueberpruefen der Antwort
        mockMvc.perform(post("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isUnprocessableEntity());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).saveBarOrder(any(BarOrder.class));
    }

    /**
     * newBarOrder: Ungültige BarOrder (BarOrderItem Menge = 0).
     * Erwartet: 400 Bad Request. (gehandled durch @Valid)
     */
    @Test
    void testNewBarOrder5() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit ungültigem BarOrderItem
        BarOrder order = new BarOrder(createTable(1), List.of());
        MenuItem item = new MenuItem(1, "Item 1", "Desc 1", 1, 1, false);
        BarOrderItem invalidItem = new BarOrderItem(order, item, 0);
        order.setItems(List.of(invalidItem));
        String json = mapper.writeValueAsString(order);
        // Ausfuehren des POST-Requests und Ueberpruefen der Antwort
        mockMvc.perform(post("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isBadRequest());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).saveBarOrder(any(BarOrder.class));
    }

    /**
     * newBarOrder: Ungültige BarOrder (archiviertes MenuItem).
     * Erwartet: 422 Unprocessable Entity
     */
    @Test
    void testNewBarOrder6() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit archiviertem MenuItem
        BarOrder order = new BarOrder(createTable(1), List.of());
        // Letzter Parameter ist das Archiv-Flag -> true = archiviert
        MenuItem archivedItem = new MenuItem(10, "Archived", "Desc", 5, 1, true);
        BarOrderItem barOrderItem = new BarOrderItem(order, archivedItem, 1);
        order.setItems(List.of(barOrderItem));
        String json = mapper.writeValueAsString(order);
        // Mock-Verhalten definieren
        when(menuItemService.getMenuItemById(archivedItem.getId())).thenReturn(archivedItem);
        // Ausfuehren des POST-Requests und Ueberpruefen der Antwort
        mockMvc.perform(post("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isForbidden());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).saveBarOrder(any(BarOrder.class));
    }
    /**
     * newBarOrder: Ungültige BarOrder (null BarTable).
     * Erwartet: 400 Bad Request.
     */
    @Test
    void testNewBarOrder7() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit null BarTable
        BarOrder invalidOrder = new BarOrder(1L, null, List.of());
        String json = mapper.writeValueAsString(invalidOrder);
        // Ausfuehren des POST-Requests und Ueberpruefen der Antwort
        mockMvc.perform(post("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isBadRequest());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).saveBarOrder(any(BarOrder.class));
    }

    // ########-PUT /barOrder-########################################################

    /**
     * updateBarOrder: Gültige BarOrder.
     * Erwartet: 204 No Content.
     */
    @Test
    void testUpdateBarOrder1() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder & updated BarOrder
        MenuItem menuItem = new MenuItem(1L, "Item", "Desc", 4.0, 1, false);
        BarOrder existing = new BarOrder(1L, createTable(1), List.of());
        BarOrderItem existingItem = new BarOrderItem(existing, menuItem, 1);
        existing.setItems(List.of(existingItem));
        BarOrder updated = new BarOrder(1L, createTable(1), List.of());
        BarOrderItem updatedItem = new BarOrderItem(updated, menuItem, 2);
        updated.setItems(List.of(updatedItem));
        String json = mapper.writeValueAsString(updated);
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(1L)).thenReturn(existing);
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isNoContent());
        // Call-Verifizierung (prüfen, dass die BarOrder aktualisiert wurde)
        verify(barOrderService).updateBarOrder(any(BarOrder.class));
    }

    /**
     * updateBarOrder: BarOrder existiert nicht.
     * Erwartet: 404 Not Found.
     */
    @Test
    void testUpdateBarOrder2() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder
        BarOrder order = createOrders(1).getFirst();
        String json = mapper.writeValueAsString(order);
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(order.getId())).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "BarOrder does not exist"));
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isNotFound());
        // Call-Verifizierung (prüfen, dass updateBarOrder nicht aufgerufen wurde)
        verify(barOrderService, never()).updateBarOrder(any(BarOrder.class));
    }

    /**
     * updateBarOrder: Ungültige BarOrder (null BarTable).
     * Erwartet: 400 Bad Request. (automatisch durch @Valid gehandled)
     */
    @Test
    void testUpdateBarOrder3() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit null BarTable
        BarOrder invalidOrder = new BarOrder(1L, null, List.of());
        String json = mapper.writeValueAsString(invalidOrder);
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isBadRequest());
        // Call-Verifizierung (prüfen, dass updateBarOrder nicht aufgerufen wurde)
        verify(barOrderService, never()).updateBarOrder(any(BarOrder.class));
    }

    /**
     * updateBarOrder: Ungültige BarOrder (ID -5).
     * Erwartet: 422 Unprocessable Entity.
     */
    @Test
    void testUpdateBarOrder4() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit ID -5
        BarOrder invalidOrder = new BarOrder(-5L, createTable(1), List.of());
        String json = mapper.writeValueAsString(invalidOrder);
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isUnprocessableEntity());
        // Call-Verifizierung (prüfen, dass updateBarOrder nicht aufgerufen wurde)
        verify(barOrderService, never()).updateBarOrder(any(BarOrder.class));
    }

    /**
     * updateBarOrder: Ungültige BarOrder (BarOrderItem Menge -5).
     * Erwartet: 400 Bad Request. (gehandled durch @Valid)
     */
    @Test
    void testUpdateBarOrder6() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit ungültigem BarOrderItem
        BarOrder order = new BarOrder(1L, createTable(1), List.of());
        MenuItem item = new MenuItem(1, "Item 1", "Desc 1", 1, 1, false);
        BarOrderItem invalidItem = new BarOrderItem(order, item, -5);
        order.setItems(List.of(invalidItem));
        String json = mapper.writeValueAsString(order);
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isBadRequest());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).updateBarOrder(any(BarOrder.class));
    }


    /**
     * updateBarOrder: Ungültige BarOrder (BarTable ID -3).
     * Erwartet: 422 Unprocessable Entity
     */
    @Test
    void testUpdateBarOrder7() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit BarTable ID -3
        BarOrder invalidOrder = new BarOrder(1L, new BarTable(-3L), List.of());
        String json = mapper.writeValueAsString(invalidOrder);
        // Ausfuehren des PUT-Requests und Ueberpruefen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isUnprocessableEntity());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).updateBarOrder(any(BarOrder.class));
    }

    /**
     * updateBarOrder: Ungültige BarOrder (BarTable Id 0).
     * Erwartet: 409 Conflict
     */
    @Test
    void testUpdateBarOrder8() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit BarTable ID 0
        BarOrder invalidOrder = new BarOrder(1L, new BarTable(0L), List.of());
        String json = mapper.writeValueAsString(invalidOrder);
        // Ausfuehren des PUT-Requests und Ueberpruefen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isUnprocessableEntity());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).updateBarOrder(any(BarOrder.class));
    }

    /**
     * updateBarOrder: Keine Änderungen an der BarOrder bei update mit selbem Objekt.
     * Erwartet: 204 No Content.
     */
    @Test
    void testUpdateBarOrder9() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder ohne Änderungen
        BarOrder original = createOrders(1).getFirst();
        String json = mapper.writeValueAsString(original);
        // Mock: gibt dasselbe JSON zurück (simuliert DB-Abruf)
        when(barOrderService.getBarOrderById(1L)).thenAnswer(inv ->
                mapper.readValue(json, BarOrder.class)
        );
        // Ausfuehren des PUT-Requests und Ueberpruefen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isNoContent());
        // Call-Verifizierung (prüfen, dass service nicht aufgerufen wurde)
        verify(barOrderService, never()).updateBarOrder(any(BarOrder.class));
    }

    /**
     * updateBarOrder: BarOrder ist archiviert.
     * Erwartet: 403 Forbidden
     */
    @Test
    void testUpdateBarOrder10() throws Exception {
        // Testvorbereitung: Erstellen einer archivierten BarOrder
        BarOrder archivedOrder = createOrders(1).getFirst();
        archivedOrder.setArchived(true);
        String json = mapper.writeValueAsString(archivedOrder);
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(archivedOrder.getId())).thenReturn(archivedOrder);
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isForbidden());
        // Call-Verifizierung (prüfen, dass updateBarOrder nicht aufgerufen wurde)
        verify(barOrderService, never()).updateBarOrder(any(BarOrder.class));
    }

    /**
     * updateBarOrder: Ungültige ID (null).
     * Erwartet: 422 Unprocessable Entity.
     */
    @Test
    void testUpdateBarOrder11() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder mit null ID
        BarOrder invalidOrder = new BarOrder(createTable(1), List.of());
        invalidOrder.setId(null);
        String json = mapper.writeValueAsString(invalidOrder);

        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isUnprocessableEntity());

        // Call-Verifizierung (prüfen, dass updateBarOrder nicht aufgerufen wurde)
        verify(barOrderService, never()).updateBarOrder(any(BarOrder.class));
    }

    // ########-PUT /barOrder/{id}/archive-########################################################
    /**
     * archiveBarOrder: BarOrder existiert.
     * Expected: 204 No Content.
     */
    @Test
    void testArchiveBarOrder1() throws Exception {
        // Testvorbereitung: Erstellen einer BarOrder
        BarOrder barOrder = createOrders(1).getFirst();
        long orderId = barOrder.getId();
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(orderId)).thenReturn(barOrder);
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder/{id}/archive", orderId))
                .andExpect(status().isNoContent());
        // Call-Verifizierung
        verify(barOrderService).archiveBarOrder(orderId);
    }

    /**
     * archiveBarOrder: BarOrder existiert nicht.
     * Expected: 404 Not Found.
     */
    @Test
    void testArchiveBarOrder2() throws Exception {
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(99L)).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "BarOrder does not exist"));
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder/{id}/archive", 99L))
                .andExpect(status().isNotFound());
        // Call-Verifizierung (prüfen, dass archiveBarOrder nicht aufgerufen wurde)
        verify(barOrderService, never()).archiveBarOrder(99L);
    }

    /**
     * archiveBarOrder: Ungültige ID (0 | -5).
     * Expected: 422 Unprocessable Entity.
     */
    @Test
    void testArchiveBarOrder3() throws Exception {
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder/{id}/archive", 0L))
                .andExpect(status().isUnprocessableEntity());
        // Call-Verifizierung (prüfen, dass archiveBarOrder nicht aufgerufen wurde)
        verify(barOrderService, never()).archiveBarOrder(anyLong());
    }
    /**
     * archiveBarOrder: Ungültige ID (-5).
     * Expected: 422 Unprocessable Entity.
     */
    @Test
    void testArchiveBarOrder4() throws Exception {
        // Ausführen des PUT-Requests und Überprüfen der Antwort
        mockMvc.perform(put("/barOrder/{id}/archive", -5L))
                .andExpect(status().isUnprocessableEntity());
        // Call-Verifizierung (prüfen, dass archiveBarOrder nicht aufgerufen wurde)
        verify(barOrderService, never()).archiveBarOrder(anyLong());
    }

    // ########-DELETE /barOrder/{id}-########################################################

    /**
     * deleteBarOrder: BarOrder existiert nicht.
     * Expected: 204 No Content. (stille Ignorierung)
     */
    @Test
    void testDeleteBarOrder1() throws Exception {
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(1L)).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "BarOrder does not exist"));
        // Ausführen des DELETE-Requests und Überprüfen der Antwort
        mockMvc.perform(delete("/barOrder/{id}", 1L))
                .andExpect(status().isNoContent());
        // Call-Verifizierung (prüfen, dass deleteBarOrderById nicht aufgerufen wurde)
        verify(barOrderService, never()).deleteBarOrderById(1L);
    }

    /**
     * deleteBarOrder: Ungültige ID (0).
     * Expected: 422 Unprocessable Entity.
     */
    @Test
    void testDeleteBarOrder2() throws Exception {
        // Ausführen des DELETE-Requests und Überprüfen der Antwort
        mockMvc.perform(delete("/barOrder/{id}", 0L))
                .andExpect(status().isUnprocessableEntity());
        // Call-Verifizierung (prüfen, dass deleteBarOrderById nicht aufgerufen wurde)
        verify(barOrderService, never()).deleteBarOrderById(anyLong());
    }

    /**
     * deleteBarOrder: Valide BarOrder.
     * Expected: 204 No Content. (Erfolgreich gelöscht)
     */
    @Test
    void testDeleteBarOrder3() throws Exception {
        long id = 1L;
        // Testvorbereitung: Erstellen einer BarOrder
        BarOrder existing = createOrders(1).getFirst();
        existing.setId(id);

        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(id)).thenReturn(existing);

        // Ausführen des DELETE-Requests und Überprüfen der Antwort
        mockMvc.perform(delete("/barOrder/{id}", id))
                .andExpect(status().isNoContent());

        // Call-Verifizierung (prüfen, dass deleteBarOrderById aufgerufen wurde)
        verify(barOrderService).deleteBarOrderById(id);
    }

    /**
     * deleteBarOrder: BarOrder ist archiviert und kann nicht gelöscht werden
     * Expected: 403 Forbidden
     */
    @Test
    void testDeleteBarOrder4() throws Exception {
        // Testvorbereitung: Erstellen einer archivierten BarOrder
        BarOrder archivedOrder = new BarOrder(7L, createTable(1), List.of());
        archivedOrder.setArchived(true);
        // Mock-Verhalten definieren
        when(barOrderService.getBarOrderById(7L)).thenReturn(archivedOrder);
        // Ausführen des DELETE-Requests und Überprüfen der Antwort
        mockMvc.perform(delete("/barOrder/{id}", 7L))
                .andExpect(status().isForbidden());
        // Call-Verifizierung (prüfen, dass deleteBarOrderById nicht aufgerufen wurde)
        verify(barOrderService, never()).deleteBarOrderById(anyLong());
    }

    /**
     * deleteBarOrder: Ungültige ID (-1).
     * Expected: 422 Unprocessable Entity.
     */
    @Test
    void testDeleteBarOrder5() throws Exception {
        // Ausführen des DELETE-Requests und Überprüfen der Antwort
        mockMvc.perform(delete("/barOrder/{id}", -1L))
                .andExpect(status().isUnprocessableEntity());
        // Call-Verifizierung (prüfen, dass deleteBarOrderById nicht aufgerufen wurde)
        verify(barOrderService, never()).deleteBarOrderById(anyLong());
    }

    /**
     * deleteBarOrder: Exception im Service wird durchgereicht. (hier eine zufällige exception simuliert)
     * Expected: Exception wird geworfen.
     */
    @Test
    void testDeleteBarOrder6() throws Exception {
        // Mock-Verhalten definieren; zufällige, sonst nicht auftretende Exception, nur um Durchreichen zu testen
        when(barOrderService.getBarOrderById(2L)).thenThrow(new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "DB error"));
        // Ausführen des DELETE-Requests und Überprüfen der Antwort
        mockMvc.perform(delete("/barOrder/{id}", 2L))
                .andExpect(status().isInternalServerError());
        // Call-Verifizierung (prüfen, dass deleteBarOrderById nicht aufgerufen wurde)
        verify(barOrderService, never()).deleteBarOrderById(2L);
    }
}
