package hm.edu.backend.services;

import hm.edu.backend.model.BarTable;
import hm.edu.backend.repositories.BarTableRepository;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
public class BarTableServiceTests {
    @InjectMocks
    BarTableServiceImpl barTableService;
    @Mock
    BarTableRepository barTableRepository;

    /**
     * getAllBarTables: keine BarTables existieren
     * Expects: leere Liste
     */
    @Test
    public void testAllTables1() {
        // Mock Vorbereitung: keine BarTables existieren
        when(barTableRepository.findAll()).thenReturn(List.of());

        // Ausfuehrung und Test der Antwort
        List<BarTable> result = barTableService.getAllBarTables();

        // Call Verifikation: findAll wurde aufgerufen
        verify(barTableRepository).findAll();

        // Ergebnis Test
        assert result != null;
        assertEquals(0, result.size());
    }

    /**
     * getAllBarTables: 3 BarTables existieren
     * Expects: Liste mit 3 BarTables
     */
    @Test
    public void testAllTables2() {
        // Mock Vorbereitung: 3 BarTables existieren
        when(barTableRepository.findAll()).thenReturn(List.of(
                new BarTable(1L),
                new BarTable(2L),
                new BarTable(3L)
        ));

        // Ausfuehrung und Test der Antwort
        List<BarTable> result = barTableService.getAllBarTables();

        // Call Verifikation: findAll wurde aufgerufen
        verify(barTableRepository).findAll();

        // Ergebnis Test
        assert result != null;
        assertEquals(3, result.size());
        assertEquals(1L, result.get(0).getId());
        assertEquals(2L, result.get(1).getId());
        assertEquals(3L, result.get(2).getId());
    }

    /**
     * getBarTableById: Service wirft Exception
     * Expects: RuntimeException
     */
    @Test
    public void testGetTable1() {
        // Mock Vorbereitung: Service wirft Exception
        when(barTableRepository.findById(1L)).thenThrow(RuntimeException.class);

        // Ausfuehrung und Test der Antwort
        Assertions.assertThrows(RuntimeException.class, () -> barTableService.getBarTableById(1L));
    }

    /**
     * getBarTableById: BarTable existiert
     * Expects: BarTable mit korrekter ID
     */
    @Test
    public void testGetTable2() {
        // Mock Vorbereitung: BarTable existiert
        when(barTableRepository.findById(1L)).thenReturn(Optional.of(new BarTable(1L)));

        // Ausfuehrung und Test der Antwort
        BarTable result = barTableService.getBarTableById(1L);

        // Call Verifikation: findById wurde aufgerufen
        verify(barTableRepository).findById(1L);

        // Ergebnis Test
        assert result != null;
        assertEquals(1L, result.getId());
    }

}
