package hm.edu.backend.services;

import hm.edu.backend.model.BarTable;

import java.util.List;

public interface BarTableService {

    /**
     * Liefert den BarTable mit der angegebenen ID.
     * @param id ID des gesuchten BarTables
     * @return BarTable mit der angegebenen ID
     */
    BarTable getBarTableById(long id);

    /**
     * Liefert alle BarTables.
     * @return Liste aller BarTables
     */
    List<BarTable> getAllBarTables();

}

