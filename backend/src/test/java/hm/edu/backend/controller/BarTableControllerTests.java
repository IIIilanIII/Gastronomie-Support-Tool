package hm.edu.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import hm.edu.backend.model.BarTable;
import hm.edu.backend.services.BarTableService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(SpringExtension.class)
@WebMvcTest(BarTableController.class)
@AutoConfigureMockMvc
/**
 * Testklasse fuer den BarTableController
 */
public class BarTableControllerTests {
    private final ObjectMapper mapper = new ObjectMapper();

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private BarTableService barTableService;

    /**
     * Testet die Methode getAllBarTables, wenn keine Tische existieren
     */
    @Test
    void testGetAllBarTables1() throws Exception {
        // Testvorbereitung: keine Tische vorhanden
        when(barTableService.getAllBarTables()).thenReturn(List.of());

        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/barTables").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(0));

        // Call Verifikation: getAllBarTables wurde aufgerufen
        verify(barTableService).getAllBarTables();
    }
    /**
     * Testet die Methode getAllBarTables, wenn zwei Tische existieren
     */
    @Test
    void testGetAllBarTables2() throws Exception {
        // Testvorbereitung: zwei Tische vorhanden
        BarTable barTable1 = new BarTable(1L);
        BarTable barTable2 = new BarTable(2L);
        List<BarTable> barTables = List.of(barTable1, barTable2);

        // Mock Vorbereitung: Service gibt die vorbereiteten Tische zurueck
        when(barTableService.getAllBarTables()).thenReturn(barTables);

        // Ausfuehrung Get Requests und Test der Antwort
        mockMvc.perform(get("/barTables").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.length()").value(2))

                .andExpect(jsonPath("$[0].id").value(1))
                .andExpect(jsonPath("$[1].id").value(2));

        // Call Verifikation: getAllBarTables wurde aufgerufen
        verify(barTableService).getAllBarTables();
    }
    /**
     * Testet die Methode getBarTableById, wenn der Tisch nicht existiert
     */
    @Test
    void testGetBarTable1() throws Exception {
        // Testvorbereitung: Tisch existiert nicht
        when(barTableService.getBarTableById(99L)).thenThrow(new RuntimeException("not found"));

        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/barTable/{id}", 99L).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());

        // Call Verifikation: getBarTableById wurde aufgerufen und hat Exception geworfen
        verify(barTableService).getBarTableById(99L);
    }
    /**
     * Testet die Methode getBarTableById, wenn der Tisch existiert
     */
    @Test
    void testGetBarTable2() throws Exception {
        // Testvorbereitung: Tisch existiert
        BarTable barTable = new BarTable(1L);
        String expectedJson = mapper.writeValueAsString(barTable);
        // Mock Vorbereitung: Service gibt den vorbereiteten Tisch zurueck
        when(barTableService.getBarTableById(barTable.getId())).thenReturn(barTable);
        // Ausfuehrung des Get Requests und Test der Antwort
        mockMvc.perform(get("/barTable/{id}", 1L).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(content().json(expectedJson));
        // Call Verifikation: getBarTableById wurde aufgerufen
        verify(barTableService).getBarTableById(1L);
    }
    /**
     * Testet die Methode getBarTableById, wenn die ID ungültig ist
     */
    @Test
    void testGetBarTable3() throws Exception {
        // Ausfuehrung des Get Requests mit ungültiger ID und Test der Antwort
        mockMvc.perform(get("/barTable/{id}", -1L).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnprocessableEntity());
        // Call Verifikation: getBarTableById wurde nicht aufgerufen
        verify(barTableService, never()).getBarTableById(-1L);
    }
}
