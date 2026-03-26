package hm.edu.backend.services;

import hm.edu.backend.model.BarTable;
import hm.edu.backend.repositories.BarTableRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BarTableServiceImpl implements BarTableService {

    @Autowired
    private BarTableRepository barTableRepository;

    /**
     * Liefert den BarTable mit der angegebenen ID.
     * @param id ID des gesuchten BarTables
     * @return BarTable mit der angegebenen ID
     */
    @Override
    public BarTable getBarTableById(long id) {
        return barTableRepository.findById(id).orElseThrow(RuntimeException::new);
    }

    /**
     * Liefert alle BarTables.
     * @return Liste aller BarTables
     */
    @Override
    public List<BarTable> getAllBarTables() {
        return barTableRepository.findAll();
    }
}

