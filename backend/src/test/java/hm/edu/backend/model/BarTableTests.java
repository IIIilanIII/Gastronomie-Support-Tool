package hm.edu.backend.model;

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class BarTableTests {

    /**
     * equals()-Methode verwendet nur die ID
     * Expects: korrekte Gleichheitsprüfung basierend auf ID
     */
    @Test
    void equalsChecksId() {
        // Testvorbereitung: drei BarTables anlegen
        BarTable a = new BarTable(1L);
        BarTable b = new BarTable(1L);
        BarTable c = new BarTable(2L);

        // Test: gleiche ID führt zu Gleichheit, unterschiedliche ID zu Ungleichheit
        assertThat(a).isEqualTo(b);
        assertThat(a).isNotEqualTo(c);

        // Test: Vergleich mit null, anderem Typ und sich selbst
        assertThat(a).isNotEqualTo(null);
        assertThat(a).isNotEqualTo("other");
        assertThat(a).isEqualTo(a);
    }
}
