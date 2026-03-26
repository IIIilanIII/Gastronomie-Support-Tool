package hm.edu.backend.repositories;

import hm.edu.backend.model.BarTable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BarTableRepository extends JpaRepository<BarTable, Long> {}

