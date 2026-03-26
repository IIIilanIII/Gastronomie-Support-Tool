package hm.edu.backend;

import hm.edu.backend.config.BarTableInitializer;
import hm.edu.backend.model.BarTable;
import hm.edu.backend.repositories.BarTableRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static org.mockito.Mockito.*;

@SpringBootTest(properties = "bartable.count=20")
public class BarTableInitializerTests {
    @MockitoBean
    private BarTableRepository repository;

    @Autowired
    private BarTableInitializer barTableInitializer;

    /**
     * Initialisierung fügt konfigurierte Anzahl an BarTables ein
     * Expects: 20 BarTables werden gespeichert bei leerem Repository
     */
    @Test
    void testInsertCorrectAmount() throws Exception {
        // Testvorbereitung: Repository-Invocations löschen und leeres Repository simulieren
        clearInvocations(repository);
        when(repository.count()).thenReturn(0L);

        // Ausführung der Initialisierung
        barTableInitializer.run();

        // Call Verifikation: save wurde 20 mal aufgerufen
        verify(repository, times(20)).save(any(BarTable.class));
    }

    /**
     * Initialisierung fügt keine BarTables ein bei vorhandenem Datenbestand
     * Expects: keine Speicherung bei nicht-leerem Repository
     */
    @Test
    void testNoInsertionIfNotEmpty() throws Exception {
        // Testvorbereitung: Repository-Invocations löschen und nicht-leeres Repository simulieren
        clearInvocations(repository);
        when(repository.count()).thenReturn(20L);

        // Ausführung der Initialisierung
        barTableInitializer.run();

        // Call Verifikation: save wurde nicht aufgerufen
        verify(repository, never()).save(any(BarTable.class));
    }
}
