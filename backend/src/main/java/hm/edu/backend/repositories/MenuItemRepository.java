package hm.edu.backend.repositories;

import hm.edu.backend.model.MenuItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MenuItemRepository extends JpaRepository<MenuItem, Long> {
    List<MenuItem> findByArchived(boolean archived);
    List<MenuItem> findByVersion(int version);
}
