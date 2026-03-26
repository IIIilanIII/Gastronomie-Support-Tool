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

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(SpringExtension.class)
@WebMvcTest(MenuItemController.class)
@AutoConfigureMockMvc
/**
 * Testklasse fuer den MenuItemController
 */
class MenuItemControllerTests {
    private final ObjectMapper mapper = new ObjectMapper();

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MenuItemService menuItemService;
    @MockitoBean
    private BarOrderService barOrderService;

    // ########-GET /menuItems-########################################################
    /**
     * getAllMenuItems: 2 menuItems existieren
     * Erwartet: 200 OK mit 2 menuItems im Body
     */
    @Test
    void testGetAllMenuItems1() throws Exception {
        // Testvorbereitung: 2 MenuItems vorhanden
        MenuItem menuItem1 = new MenuItem(1L, "Schönramer Hell", "as greane", 2.3, 1, false);
        MenuItem menuItem2 = new MenuItem(2L, "Cola Mix", "a guada Flötzinger", 1.8, 1, false);
        List<MenuItem> menuItems = List.of(menuItem1, menuItem2);
        // Mock Vorbereitung: menuItemService.getAllMenuItems() liefert die 2 MenuItems
        when(menuItemService.getAllMenuItems()).thenReturn(menuItems);
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(2))

                .andExpect(jsonPath("$[0].id").value(1))
                .andExpect(jsonPath("$[0].name").value("Schönramer Hell"))
                .andExpect(jsonPath("$[0].description").value("as greane"))
                .andExpect(jsonPath("$[0].price").value(2.3))
                .andExpect(jsonPath("$[0].version").value(1))
                .andExpect(jsonPath("$[0].archived").value(false))

                .andExpect(jsonPath("$[1].id").value(2))
                .andExpect(jsonPath("$[1].name").value("Cola Mix"))
                .andExpect(jsonPath("$[1].description").value("a guada Flötzinger"))
                .andExpect(jsonPath("$[1].price").value(1.8))
                .andExpect(jsonPath("$[1].version").value(1))
                .andExpect(jsonPath("$[1].archived").value(false));
        // Call Verifikation: getAllMenuItems wurde aufgerufen
        verify(menuItemService).getAllMenuItems();
    }

    /**
     * getAllMenuItems: keine menuItems existieren
     * Expects: 200 OK mit leerem Array im Body
     */
    @Test
    void testGetAllMenuItems2() throws Exception {
        // Mock Vorbereitung: keine MenuItems vorhanden
        when(menuItemService.getAllMenuItems()).thenReturn(List.of());
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(0));
        // Call Verifikation: getAllMenuItems wurde aufgerufen
        verify(menuItemService).getAllMenuItems();
    }

    /**
     * getAllMenuItems by archived=true; keine MenuItems vorhanden
     * Expects: 200 OK mit leerem Array im Body
     */
    @Test
    void testGetAllMenuItemsByArchived1() throws Exception {
        // Mock Vorbereitung: Service liefert für archived=true und archived=false jeweils eine leere Liste
        when(menuItemService.getAllMenuItemsByArchived(false)).thenReturn(List.of());
        when(menuItemService.getAllMenuItemsByArchived(true)).thenReturn(List.of());
        // Ausführung des GET‑Requests mit archived=true und Test der Antwort
        mockMvc.perform(get("/menuItems").param("archived", "true").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(0));
        // Verifikation: getAllMenuItemsByArchived(true) wurde aufgerufen
        verify(menuItemService).getAllMenuItemsByArchived(true);
    }

    /**
     * getAllMenuItems by archived=false; keine MenuItems vorhanden
     * Expects: 200 OK mit leerem Array im Body
     */
    @Test
    void testGetAllMenuItemsByArchived2() throws Exception {
        // Mock Vorbereitung: keine MenuItems vorhanden
        when(menuItemService.getAllMenuItemsByArchived(false)).thenReturn(List.of());
        when(menuItemService.getAllMenuItemsByArchived(true)).thenReturn(List.of());
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").param("archived", "false").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(0));
        // Call Verifikation: getAllMenuItemsByArchived wurde aufgerufen
        verify(menuItemService).getAllMenuItemsByArchived(false);
    }

    /**
     * getAllMenuItems: 3 menuItems existieren, 2 archiviert
     * Expects: 200 OK mit 2 archivierten menuItems im Body
     */
    @Test
    void testGetAllMenuItemsByArchived3() throws Exception {
        // Testvorbereitung: 3 MenuItems vorhanden
        MenuItem menuItem1 = new MenuItem(1L, "Schönramer Hell", "as greane", 2.3, 1, false);
        MenuItem menuItem2 = new MenuItem(2L, "Cola Mix", "a guada Flötzinger", 1.8, 1, true);
        MenuItem menuItem3 = new MenuItem(3L, "Item3", "Desc3", 4.5, 1, true);
        // Mock Vorbereitung: menuItemService.getAllMenuItemsByArchived(true) liefert die 2 archivierten MenuItems
        when(menuItemService.getAllMenuItemsByArchived(true)).thenReturn(List.of(menuItem2, menuItem3));
        when(menuItemService.getAllMenuItemsByArchived(false)).thenReturn(List.of(menuItem1));
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").param("archived", "true").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(2))

                .andExpect(jsonPath("$[0].id").value(2))
                .andExpect(jsonPath("$[0].name").value("Cola Mix"))
                .andExpect(jsonPath("$[0].description").value("a guada Flötzinger"))
                .andExpect(jsonPath("$[0].price").value(1.8))
                .andExpect(jsonPath("$[0].version").value(1))
                .andExpect(jsonPath("$[0].archived").value(true))

                .andExpect(jsonPath("$[1].id").value(3))
                .andExpect(jsonPath("$[1].name").value("Item3"))
                .andExpect(jsonPath("$[1].description").value("Desc3"))
                .andExpect(jsonPath("$[1].price").value(4.5))
                .andExpect(jsonPath("$[1].version").value(1))
                .andExpect(jsonPath("$[1].archived").value(true));
        // Call Verifikation: getAllMenuItemsByArchived wurde aufgerufen
        verify(menuItemService).getAllMenuItemsByArchived(true);
    }

    /**
     * getAllMenuItems: 3 menuItems existieren, 1 nicht archiviert
     * Expects: 200 OK mit 1 nicht archivierten menuItem im Body
     */
    @Test
    void testGetAllMenuItemsByArchived4() throws Exception {
        // Testvorbereitung: 3 MenuItems vorhanden
        MenuItem menuItem1 = new MenuItem(1L, "Schönramer Hell", "as greane", 2.3, 1, false);
        MenuItem menuItem2 = new MenuItem(2L, "Cola Mix", "a guada Flötzinger", 1.8, 1, true);
        MenuItem menuItem3 = new MenuItem(3L, "Item3", "Desc3", 4.5, 1, true);
        // Mock Vorbereitung: menuItemService.getAllMenuItemsByArchived(false) liefert das 1 nicht archivierte MenuItem
        when(menuItemService.getAllMenuItemsByArchived(false)).thenReturn(List.of(menuItem1));
        when(menuItemService.getAllMenuItemsByArchived(true)).thenReturn(List.of(menuItem2, menuItem3));
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").param("archived", "false").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(1))

                .andExpect(jsonPath("$[0].id").value(1))
                .andExpect(jsonPath("$[0].name").value("Schönramer Hell"))
                .andExpect(jsonPath("$[0].description").value("as greane"))
                .andExpect(jsonPath("$[0].price").value(2.3))
                .andExpect(jsonPath("$[0].version").value(1))
                .andExpect(jsonPath("$[0].archived").value(false));
        // Call Verifikation: getAllMenuItemsByArchived wurde aufgerufen
        verify(menuItemService).getAllMenuItemsByArchived(false);
    }

    /**
     * getAllMenuItems: archived=abc
     * Expects: 422 Unprocessable Entity
     */
    @Test
    void testGetAllMenuItemsByArchivedNonBoolean() throws Exception {
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").param("archived", "abc"))
                .andExpect(status().isUnprocessableEntity());
        // Call Verifikation: getAllMenuItemsByArchived wurde nicht aufgerufen
        verify(menuItemService, never()).getAllMenuItemsByArchived(anyBoolean());
    }

    /**
     * getAllMenuItems: archived="" (blank)
     * Erwartet: 422 Unprocessable Entity
     */
    @Test
    void testGetALlMenuItemsByArchivedBlank() throws Exception {
        // Ausführung des GET‑Requests mit archived="" und Test der Antwort
        mockMvc.perform(get("/menuItems").param("archived", ""))
                .andExpect(status().isUnprocessableEntity());

        // Call Verifikation: getAllMenuItemsByArchived wurde nicht aufgerufen
        verify(menuItemService, never()).getAllMenuItemsByArchived(anyBoolean());
    }

    /**
     * getAllMenuItems by version=2; keine items existieren
     * Expects: 200 OK mit leerem Array im Body
     */
    @Test
    void testGetAllMenuItemsByVersion1() throws Exception {
        // Mock Vorbereitung: keine MenuItems vorhanden
        when(menuItemService.getAllMenuItemsByVersion(2)).thenReturn(List.of());
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").param("version", "2").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(0));
        // Call Verifikation: getAllMenuItemsByVersion wurde aufgerufen
        verify(menuItemService).getAllMenuItemsByVersion(2);
    }

    /**
     * getAllMenuItems by version=2; 3 existieren, 2 passende version
     * Expects: 200 OK mit 2 menuItems im Body
     */
    @Test
    void testGetAllMenuItemsByVersion2() throws Exception {
        // Testvorbereitung: 3 MenuItems vorhanden
        MenuItem menuItem1 = new MenuItem(1L, "Schönramer Hell", "as greane", 2.3, 1, false);
        MenuItem menuItem2 = new MenuItem(2L, "Cola Mix", "a guada Flötzinger", 1.8, 2, true);
        MenuItem menuItem3 = new MenuItem(3L, "Item3", "Desc3", 4.5, 2, false);
        // Mock Vorbereitung; 3 menu items exist; 2 matching version=2
        when(menuItemService.getAllMenuItemsByVersion(2)).thenReturn(List.of(menuItem2, menuItem3));
        when(menuItemService.getAllMenuItemsByVersion(1)).thenReturn(List.of(menuItem1));
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").param("version", "2").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(2))

                .andExpect(jsonPath("$[0].id").value(2))
                .andExpect(jsonPath("$[0].name").value("Cola Mix"))
                .andExpect(jsonPath("$[0].description").value("a guada Flötzinger"))
                .andExpect(jsonPath("$[0].price").value(1.8))
                .andExpect(jsonPath("$[0].version").value(2))
                .andExpect(jsonPath("$[0].archived").value(true))

                .andExpect(jsonPath("$[1].id").value(3))
                .andExpect(jsonPath("$[1].name").value("Item3"))
                .andExpect(jsonPath("$[1].description").value("Desc3"))
                .andExpect(jsonPath("$[1].price").value(4.5))
                .andExpect(jsonPath("$[1].version").value(2))
                .andExpect(jsonPath("$[1].archived").value(false));
        // Call Verifikation: getAllMenuItemsByVersion wurde aufgerufen
        verify(menuItemService).getAllMenuItemsByVersion(2);
    }

    /**
     * getAllMenuItems by version=1; 3 existieren, 1 passende version
     * Expects: 200 OK mit 1 menuItem im Body
     */
    @Test
    void testGetAllMenuItemsByVersion3() throws Exception {
        // Testvorbereitung: 3 MenuItems vorhanden
        MenuItem menuItem1 = new MenuItem(1L, "Schönramer Hell", "as greane", 2.3, 1, false);
        MenuItem menuItem2 = new MenuItem(2L, "Cola Mix", "a guada Flötzinger", 1.8, 2, true);
        MenuItem menuItem3 = new MenuItem(3L, "Item3", "Desc3", 4.5, 2, false);
        // Mock Vorbereitung; 3 menu items existieren; 1 matching version=1
        when(menuItemService.getAllMenuItemsByVersion(1)).thenReturn(List.of(menuItem1));
        when(menuItemService.getAllMenuItemsByVersion(2)).thenReturn(List.of(menuItem2, menuItem3));
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").param("version", "1").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(1))

                .andExpect(jsonPath("$[0].id").value(1))
                .andExpect(jsonPath("$[0].name").value("Schönramer Hell"))
                .andExpect(jsonPath("$[0].description").value("as greane"))
                .andExpect(jsonPath("$[0].price").value(2.3))
                .andExpect(jsonPath("$[0].version").value(1))
                .andExpect(jsonPath("$[0].archived").value(false));
        // Call Verifikation: getAllMenuItemsByVersion wurde aufgerufen
        verify(menuItemService).getAllMenuItemsByVersion(1);
    }

    /**
     * getAllMenuItems by version=abc
     * Expects: 400 Bad Request
     */
    @Test
    void testGetAllMenuItemsByVersionNonNumeric() throws Exception {
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItems").param("version", "abc"))
                .andExpect(status().isBadRequest());
        // Call Verifikation: getAllMenuItemsByVersion wurde nicht aufgerufen
        verify(menuItemService, never()).getAllMenuItemsByVersion(anyInt());
    }
    /**
     * Get all menuItems by version=-2
     */
    @Test
    void testGetAllMenuItemsByVersionNegative() throws Exception {
        // perform test
        mockMvc.perform(get("/menuItems").param("version", "-2"))
                .andExpect(status().isUnprocessableEntity());

        // verify getAllMenuItemsByVersion has been called
        verify(menuItemService, never()).getAllMenuItemsByVersion(anyInt());
    }

    /**
     * Get all menuItems by version=2 AND archived=true
     */
    @Test
    void testGetAllMenuItemsFilteredBothSet() throws Exception {
        // perform test
        mockMvc.perform(get("/menuItems").param("version", "2").param("archived", "true"))
                .andExpect(status().isMethodNotAllowed());

        // verify neither getAllMenuItemsByVersion nor getAllMenuItemsByArchived has been called
        verify(menuItemService, never()).getAllMenuItemsByVersion(anyInt());
        verify(menuItemService, never()).getAllMenuItemsByArchived(anyBoolean());
    }

    /**
     * Insert new menuItem; empty body
     */
    @Test
    void testNewMenuItem1() throws Exception {
        // perform test: empty body
        mockMvc.perform(post("/menuItem")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(""))
                .andExpect(status().isBadRequest());

        // verify saveMenuItem has not been called
        verify(menuItemService, never()).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Insert new menuItem; valid body
     */
    @Test
    void testNewMenuItem2() throws Exception {
        MenuItem newItem = new MenuItem("New Menu Item", "Menu Item Desc", 2.9, 1, false);
        String json = mapper.writeValueAsString(newItem);

        // perform test: no return value
        mockMvc.perform(post("/menuItem")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(json))
                .andExpect(status().isNoContent());

        // verify saveMenuItem has been called
        verify(menuItemService).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Einfügen eines neuen MenuItem; ID mitgesendet
     * Expects: 403 Forbidden
     */
    @Test
    void testNewMenuItemIdPresent() throws Exception {
        // Testvorbereitung: MenuItem mit ID anlegen
        MenuItem newItem = new MenuItem(1L, "New Menu Item", "Menu Item Desc", 2.9, 1, false);
        String json = mapper.writeValueAsString(newItem);

        // Ausfuehrung des Post Requests und Test der Antwort
        mockMvc.perform(post("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isForbidden());

        // Call Verifikation: saveMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Einfügen eines neuen MenuItem; ungültiges JSON, fehlendes Komma
     * Expects: 400 Bad Request
     */
    @Test
    void testNewMenuItemInvalidJson1() throws Exception {
        // Testvorbereitung: ungültiges JSON mit fehlendem Komma
        String json = "{\"id\":null\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":1,\"archived\":false}";

        // Ausfuehrung des Post Requests und Test der Antwort
        mockMvc.perform(post("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isBadRequest());

        // Call Verifikation: saveMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Einfügen eines neuen MenuItem; ungültiges JSON, ungültiges Attribut vorhanden
     * Expects: 400 Bad Request
     */
    @Test
    void testNewMenuItemInvalidJson2() throws Exception {
        // Testvorbereitung: JSON mit ungültigem Attribut
        String json = "{\"id\":null,\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":1,\"archived\":false,\"badVal\":3}";

        // Ausfuehrung des Post Requests und Test der Antwort
        mockMvc.perform(post("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isBadRequest());
    }

    /**
     * Einfügen eines neuen MenuItem; ungültiges JSON, erforderlicher Wert null
     * Expects: 400 Bad Request
     */
    @Test
    void testNewMenuItemInvalidJson3() throws Exception {
        // Testvorbereitung: JSON mit null als Name
        String json = "{\"id\":null,\"name\":null,\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":1,\"archived\":false}";

        // Ausfuehrung des Post Requests und Test der Antwort
        mockMvc.perform(post("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isBadRequest());

        // Call Verifikation: saveMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Einfügen eines neuen MenuItem; ungültiges JSON, erforderlicher Wert fehlt
     * Expects: 400 Bad Request
     */
    @Test
    void testNewMenuItemInvalidJson4() throws Exception {
        // Testvorbereitung: JSON ohne Name-Attribut
        String json = "{\"id\":null,\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":1,\"archived\":false}";

        // Ausfuehrung des Post Requests und Test der Antwort
        mockMvc.perform(post("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isBadRequest());

        // Call Verifikation: saveMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Einfügen eines neuen MenuItem; ungültiges JSON, negativer Preis
     * Expects: 400 Bad Request
     */
    @Test
    void testNewMenuItemInvalidJson5() throws Exception {
        // Testvorbereitung: JSON mit negativem Preis
        String json = "{\"id\":null,\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":-2.9,\"version\":1,\"archived\":false}";

        // Ausfuehrung des Post Requests und Test der Antwort
        mockMvc.perform(post("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isBadRequest());

        // Call Verifikation: saveMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Einfügen eines neuen MenuItem; ungültiges JSON, Version ist 0
     * Expects: 400 Bad Request
     */
    @Test
    void testNewMenuItemInvalidJson6() throws Exception {
        // Testvorbereitung: JSON mit Version 0
        String json = "{\"id\":null,\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":0,\"archived\":false}";

        // Ausfuehrung des Post Requests und Test der Antwort
        mockMvc.perform(post("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isBadRequest());

        // Call Verifikation: saveMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Einfügen eines neuen MenuItem; ungültiges JSON, Version ist 2 (muss bei Erstellung 1 sein)
     * Expects: 403 Forbidden
     */
    @Test
    void testNewMenuItemInvalidJson7() throws Exception {
        // Testvorbereitung: JSON mit Version 2
        String json = "{\"id\":null,\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":2,\"archived\":false}";

        // Ausfuehrung des Post Requests und Test der Antwort
        mockMvc.perform(post("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isForbidden());

        // Call Verifikation: saveMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Einfügen eines neuen MenuItem; ungültiges JSON, archived ist true
     * Expects: 403 Forbidden
     */
    @Test
    void testNewMenuItemInvalidJson8() throws Exception {
        // Testvorbereitung: JSON mit archived=true
        String json = "{\"id\":null,\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":1,\"archived\":true}";

        // Ausfuehrung des Post Requests und Test der Antwort
        mockMvc.perform(post("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isForbidden());

        // Call Verifikation: saveMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).saveMenuItem(any(MenuItem.class));
    }

    /**
     * Abrufen eines MenuItem per ID; passendes MenuItem existiert
     * Expects: 200 OK
     */
    @Test
    void testGetMenuItem1() throws Exception {
        // Testvorbereitung: MenuItem anlegen
        MenuItem menuItem = new MenuItem(5L, "Menu Item", "Menu Item Desc", 4.6, 1, false);

        // Mock Vorbereitung: menuItemService.getMenuItemById() liefert das MenuItem
        when(menuItemService.getMenuItemById(5L)).thenReturn(menuItem);

        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItem/{id}", 5L)
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(5))
                .andExpect(jsonPath("$.name").value("Menu Item"))
                .andExpect(jsonPath("$.description").value("Menu Item Desc"))
                .andExpect(jsonPath("$.price").value(4.6))
                .andExpect(jsonPath("$.version").value(1))
                .andExpect(jsonPath("$.archived").value(false));

        // Call Verifikation: getMenuItemById wurde aufgerufen
        verify(menuItemService).getMenuItemById(5L);
    }

    /**
     * Abrufen eines MenuItem per ID; kein MenuItem existiert
     * Expects: 404 Not Found
     */
    @Test
    void testGetMenuItem2() throws Exception {
        // Mock Vorbereitung: menuItemService.getMenuItemById() wirftNotFoundException
        when(menuItemService.getMenuItemById(99L)).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Menu Item does not exist"));

        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItem/{id}", 99L)
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());

        // Call Verifikation: getMenuItemById wurde aufgerufen
        verify(menuItemService).getMenuItemById(99L);
    }

    /**
     * Abrufen eines MenuItem per ID; ID nicht numerisch
     * Expects: 400 Bad Request
     */
    @Test
    void testGetMenuItemNonNumeric() throws Exception {
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/menuItem/{id}", "abc").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());

        // Call Verifikation: getMenuItemById wurde nicht aufgerufen
        verify(menuItemService, never()).getMenuItemById(anyLong());
    }

    /**
     * Abrufen eines MenuItem per ID; ID negativ oder 0
     * Expects: 422 Unprocessable Entity
     */
    @Test
    void testGetMenuItemNegative() throws Exception {
        // Ausfuehrung der Get Requests mit negativer ID und ID 0 und Test der Antworten
        mockMvc.perform(get("/menuItem/{id}", -3).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnprocessableEntity());

        mockMvc.perform(get("/menuItem/{id}", 0).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnprocessableEntity());

        // Call Verifikation: getMenuItemById wurde nicht aufgerufen
        verify(menuItemService, never()).getMenuItemById(-3);
        verify(menuItemService, never()).getMenuItemById(0);
    }

    /**
     * Aktualisieren eines MenuItem; MenuItem existiert nicht
     * Expects: 404 Not Found
     */
    @Test
    void testUpdateMenuItem1() throws Exception {
        // Testvorbereitung: MenuItem anlegen
        MenuItem updated = new MenuItem(2L, "Updated", "Updated Desc", 6.8, 1, false);

        // Mock Vorbereitung: menuItemService.getMenuItemById() wirftNotFoundException
        when(menuItemService.getMenuItemById(2L)).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Menu Item does not exist"));

        // Ausfuehrung des Put Requests und Test der Antwort
        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(updated)))
                .andExpect(status().isNotFound());

        // Call Verifikation: updateMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).updateMenuItem(any(MenuItem.class));
    }

    /**
     * Aktualisieren eines MenuItem; passendes MenuItem existiert, gültiger Body
     * Expects: 204 No Content
     */
    @Test
    void testUpdateMenuItem2() throws Exception {
        // Testvorbereitung: existierendes und aktualisiertes MenuItem anlegen
        MenuItem existing = new MenuItem(2L, "existing", "existing Desc", 6.7, 1, false);
        MenuItem updated = new MenuItem(2L, "Updated", "Updated Desc", 6.8, 1, false);

        // Mock Vorbereitung: menuItemService.getMenuItemById() liefert das existierende MenuItem
        when(menuItemService.getMenuItemById(2L)).thenReturn(existing);

        // Ausfuehrung des Put Requests und Test der Antwort
        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(updated)))
                .andExpect(status().isNoContent());

        // Call Verifikation: updateMenuItem wurde aufgerufen
        verify(menuItemService).updateMenuItem(refEq(updated));
    }

    /**
     * Aktualisieren eines MenuItem; leerer Body
     * Expects: 400 Bad Request
     */
    @Test
    void testUpdateMenuItem3() throws Exception {
        // Ausfuehrung des Put Requests und Test der Antwort
        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(""))
                .andExpect(status().isBadRequest());

        // Call Verifikation: updateMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).updateMenuItem(any(MenuItem.class));
    }

    /**
     * Aktualisieren eines MenuItem; passendes MenuItem existiert, ist aber archiviert
     * Expects: 403 Forbidden
     */
    @Test
    void testUpdateMenuItem4() throws Exception {
        // Testvorbereitung: existierendes archiviertes und aktualisiertes MenuItem anlegen
        MenuItem existing = new MenuItem(2L, "existing", "existing Desc", 6.7, 1, true);
        MenuItem updated = new MenuItem(2L, "Updated", "Updated Desc", 6.8, 1, true);

        // Mock Vorbereitung: menuItemService.getMenuItemById() liefert das archivierte MenuItem
        when(menuItemService.getMenuItemById(2L)).thenReturn(existing);

        // Ausfuehrung des Put Requests und Test der Antwort
        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(updated)))
                .andExpect(status().isForbidden());

        // Call Verifikation: updateMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).updateMenuItem(any(MenuItem.class));
    }

    /**
     * Aktualisieren eines MenuItem; ID fehlt oder ungültiger Wert
     * Expects: 422 Unprocessable Entity
     */
    @Test
    void testUpdateMenuItemIdInvalid() throws Exception {
        // Testvorbereitung: JSON mit ID null, ohne ID, mit negativer ID und mit ID 0
        String json1 = "{\"id\":null,\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":1,\"archived\":false}";
        String json2 = "{\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":1,\"archived\":false}";
        String json3 = "{\"id\":-3,\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":1,\"archived\":false}";
        String json4 = "{\"id\":0,\"name\":\"New Menu Item\",\"description\":\"Menu Item Desc\",\"price\":2.9,\"version\":1,\"archived\":false}";

        // Ausfuehrung der Put Requests und Test der Antworten
        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json1))
                .andExpect(status().isUnprocessableEntity());

        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json2))
                .andExpect(status().isUnprocessableEntity());

        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json3))
                .andExpect(status().isUnprocessableEntity());

        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json4))
                .andExpect(status().isUnprocessableEntity());

        // Call Verifikation: updateMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).updateMenuItem(any(MenuItem.class));
    }

    /**
     * Aktualisieren eines MenuItem; archived kann gesetzt werden
     * Expects: 204 No Content
     */
    @Test
    void testUpdateMenuItemCanArchive() throws Exception {
        // Testvorbereitung: existierendes und aktualisiertes MenuItem anlegen
        MenuItem existing = new MenuItem(1L, "Item Name", "Item Desc", 2.9, 1, false);
        MenuItem updated = new MenuItem(1L, "Item Name", "Item Desc", 2.9, 1, true);
        String json = mapper.writeValueAsString(updated);

        // Mock Vorbereitung: menuItemService.getMenuItemById() liefert das existierende MenuItem
        when(menuItemService.getMenuItemById(existing.getId())).thenReturn(existing);

        // Ausfuehrung des Put Requests und Test der Antwort
        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isNoContent());

        // Call Verifikation: updateMenuItem wurde aufgerufen
        verify(menuItemService).updateMenuItem(any(MenuItem.class));
    }

    /**
     * Aktualisieren eines MenuItem; passendes MenuItem existiert, aber nichts geändert
     * Expects: 204 No Content
     */
    @Test
    void testUpdateMenuItemNothingChanged() throws Exception {
        // Testvorbereitung: existierendes und aktualisiertes MenuItem anlegen
        MenuItem existing = new MenuItem(1L, "Item Name", "Item Desc", 2.9, 1, false);
        MenuItem updated = new MenuItem(1L, "Item Name", "Item Desc", 2.9, 1, false);
        String json = mapper.writeValueAsString(updated);

        // Mock Vorbereitung: menuItemService.getMenuItemById() liefert das existierende MenuItem
        when(menuItemService.getMenuItemById(existing.getId())).thenReturn(existing);

        // Ausfuehrung des Put Requests und Test der Antwort
        mockMvc.perform(put("/menuItem")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isNoContent());

        // Call Verifikation: updateMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).updateMenuItem(any(MenuItem.class));
    }

    /**
     * Löschen eines MenuItem; kein MenuItem existiert
     * Expects: 204 No Content
     */
    @Test
    void testDeleteMenuItem1() throws Exception {
        // Mock Vorbereitung: menuItemService.getMenuItemById() wirftNotFoundException
        when(menuItemService.getMenuItemById(3L)).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Menu Item does not exist"));

        // Ausfuehrung des Delete Requests und Test der Antwort
        mockMvc.perform(delete("/menuItem/{id}", 3L))
                .andExpect(status().isNoContent());

        // Call Verifikation: deleteMenuItemById wurde nicht aufgerufen
        verify(menuItemService, never()).deleteMenuItemById(3L);
    }

    /**
     * Löschen eines MenuItem; passendes MenuItem existiert
     * Expects: 204 No Content
     */
    @Test
    void testDeleteMenuItem2() throws Exception {
        // Testvorbereitung: MenuItem anlegen
        MenuItem existing = new MenuItem(1L, "Item name", "Item desc", 2.9, 1, false);

        // Mock Vorbereitung: menuItemService.getMenuItemById() liefert das MenuItem
        when(menuItemService.getMenuItemById(existing.getId())).thenReturn(existing);

        // Ausfuehrung des Delete Requests und Test der Antwort
        mockMvc.perform(delete("/menuItem/{id}", existing.getId()))
                .andExpect(status().isNoContent());

        // Call Verifikation: deleteMenuItemById wurde aufgerufen
        verify(menuItemService).deleteMenuItemById(existing.getId());
    }

    /**
     * Löschen eines MenuItem; MenuItem in offener BarOrder enthalten
     * Expects: 403 Forbidden
     */
    @Test
    void testDeleteMenuItemInOpenOrder() throws Exception {
        // Testvorbereitung: 2 MenuItems anlegen
        MenuItem menuItem1 = new MenuItem(1L, "Item1", "Desc1", 2.9, 1, false);
        MenuItem menuItem2 = new MenuItem(2L, "Item2", "Desc2", 1.7, 2, false);

        // Testvorbereitung: 2 BarOrders mit je einem MenuItem anlegen
        BarOrder barOrder1 = new BarOrder(1L, new BarTable(1), List.of());
        BarOrderItem barOrderItem1 = new BarOrderItem(barOrder1, menuItem1, 5);
        barOrder1.setItems(List.of(barOrderItem1));
        BarOrder barOrder2 = new BarOrder(2L, new BarTable(2), List.of());
        BarOrderItem barOrderItem2 = new BarOrderItem(barOrder2, menuItem2, 2);
        barOrder2.setItems(List.of(barOrderItem2));

        // Mock Vorbereitung: menuItemService.getMenuItemById() liefert die MenuItems
        when(menuItemService.getMenuItemById(menuItem1.getId())).thenReturn(menuItem1);
        when(menuItemService.getMenuItemById(menuItem2.getId())).thenReturn(menuItem2);
        // Mock Vorbereitung: barOrderService.getAllBarOrders() liefert die BarOrders
        when(barOrderService.getAllBarOrders()).thenReturn(List.of(barOrder1, barOrder2));

        // Ausfuehrung des Delete Requests und Test der Antwort
        mockMvc.perform(delete("/menuItem/{id}", menuItem2.getId()))
                .andExpect(status().isForbidden());

        // Call Verifikation: updateMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).updateMenuItem(any(MenuItem.class));
    }

    /**
     * Löschen eines MenuItem; MenuItem ist archiviert
     * Expects: 403 Forbidden
     */
    @Test
    void testDeleteMenuItemArchived() throws Exception {
        // Testvorbereitung: archiviertes MenuItem anlegen
        MenuItem menuItem = new MenuItem(1L, "Item", "Desc", 2.9, 1, true);
        // Testvorbereitung: BarOrder mit MenuItem anlegen
        BarOrder barOrder = new BarOrder(1L, new BarTable(1), List.of());
        BarOrderItem barOrderItem = new BarOrderItem(barOrder, menuItem, 5);
        barOrder.setItems(List.of(barOrderItem));

        // Mock Vorbereitung: menuItemService.getMenuItemById() liefert das archivierte MenuItem
        when(menuItemService.getMenuItemById(menuItem.getId())).thenReturn(menuItem);
        // Mock Vorbereitung: barOrderService.getAllBarOrders() liefert die BarOrder
        when(barOrderService.getAllBarOrders()).thenReturn(List.of(barOrder));

        // Ausfuehrung des Delete Requests und Test der Antwort
        mockMvc.perform(delete("/menuItem/{id}", menuItem.getId()))
                .andExpect(status().isForbidden());

        // Call Verifikation: updateMenuItem wurde nicht aufgerufen
        verify(menuItemService, never()).updateMenuItem(any(MenuItem.class));
    }

    /**
     * Löschen eines MenuItem; ID kleiner als 1
     * Expects: 422 Unprocessable Entity
     */
    @Test
    void testDeleteMenuItemNonPositiveId() throws Exception {
        // Ausfuehrung der Delete Requests mit ID 0 und negativer ID und Test der Antworten
        mockMvc.perform(delete("/menuItem/{id}", 0))
                .andExpect(status().isUnprocessableEntity());

        mockMvc.perform(delete("/menuItem/{id}", -2))
                .andExpect(status().isUnprocessableEntity());

        // Call Verifikation: deleteMenuItemById wurde nicht aufgerufen
        verify(menuItemService, never()).deleteMenuItemById(anyInt());
    }

}