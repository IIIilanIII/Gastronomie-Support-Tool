package hm.edu.backend.config;

import hm.edu.backend.model.BarTable;
import hm.edu.backend.repositories.BarTableRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

/**
 * Initialisiert die BarTable-Eintraege in der Datenbank beim Start der Anwendung
 */
@Component
public class BarTableInitializer implements CommandLineRunner {
    private final BarTableRepository barTableRepository;
    // Anzahl der zu erstellenden BarTables konfigurierbar ueber application.properties
    @Value("${bartable.count}")
    private int barTableCount;
    /**
     * Konstruktor fuer BarTableInitializer
     * @param barTableRepository Repository fuer BarTable-Entitaeten
     */
    public BarTableInitializer(BarTableRepository barTableRepository) {
        this.barTableRepository = barTableRepository;
    }
    // Fuehrt die Initialisierung der BarTables durch
    @Override
    public void run(String... args) throws Exception {
        if (barTableRepository.count() == 0) {
            for (int i = 0; i < barTableCount; i++) {
                barTableRepository.save(new BarTable());
            }
        }
    }
}
