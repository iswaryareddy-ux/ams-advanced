<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String pageTitle = "Dashboard";
    String pageSubtitle = "A live snapshot of every asset in the registry";
    String activePage = "dashboard";

    int totalAssets = 0, inUse = 0, available = 0, underRepair = 0, expiredWarranty = 0, disposed = 0;
    List<Map<String,Object>> categoryBreakdown = new ArrayList<>();
    List<Map<String,Object>> recentActivity = new ArrayList<>();
    List<Map<String,Object>> warrantyWatch = new ArrayList<>();
    boolean dbOk = true;

    try (Connection con = DBConnection.getConnection()) {

        // Status counts
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT status, COUNT(*) c FROM assets GROUP BY status");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String st = rs.getString("status");
                int c = rs.getInt("c");
                totalAssets += c;
                if ("In Use".equals(st)) inUse = c;
                else if ("Available".equals(st)) available = c;
                else if ("Under Repair".equals(st)) underRepair = c;
                else if ("Disposed".equals(st)) disposed = c;
            }
        }

        // Expired / soon-to-expire warranty count (within 60 days, excluding disposed)
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) c FROM assets WHERE warranty_expiry IS NOT NULL " +
                "AND warranty_expiry <= DATE_ADD(CURDATE(), INTERVAL 60 DAY) AND status <> 'Disposed'");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) expiredWarranty = rs.getInt("c");
        }

        // Category breakdown
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT c.category_name, COUNT(a.asset_id) cnt FROM asset_categories c " +
                "LEFT JOIN assets a ON a.category_id = c.category_id " +
                "GROUP BY c.category_id, c.category_name HAVING cnt > 0 ORDER BY cnt DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                row.put("name", rs.getString("category_name"));
                row.put("count", rs.getInt("cnt"));
                categoryBreakdown.add(row);
            }
        }

        // Recent activity (audit trail)
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT username, action, entity, entity_id, details, created_at " +
                "FROM audit_log ORDER BY created_at DESC LIMIT 8");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                row.put("username", rs.getString("username"));
                row.put("action", rs.getString("action"));
                row.put("entity", rs.getString("entity"));
                row.put("entity_id", rs.getString("entity_id"));
                row.put("details", rs.getString("details"));
                row.put("created_at", rs.getTimestamp("created_at"));
                recentActivity.add(row);
            }
        }

        // Warranty watch list
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT asset_id, asset_name, warranty_expiry FROM assets " +
                "WHERE warranty_expiry IS NOT NULL AND status <> 'Disposed' " +
                "AND warranty_expiry <= DATE_ADD(CURDATE(), INTERVAL 60 DAY) " +
                "ORDER BY warranty_expiry ASC LIMIT 5");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                row.put("asset_id", rs.getString("asset_id"));
                row.put("asset_name", rs.getString("asset_name"));
                row.put("warranty_expiry", rs.getDate("warranty_expiry"));
                warrantyWatch.add(row);
            }
        }

    } catch (Exception ex) {
        // Fallback demo values so the page still renders if the DB isn't connected yet
        dbOk = false;
        totalAssets = 10; inUse = 5; available = 2; underRepair = 1; disposed = 1; expiredWarranty = 2;
    }
%>
<%@ include file="includes/header.jsp" %>

  <% if (!dbOk) { %>
  <div class="alert alert-info">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
    <div>Couldn't reach the database, so this page is showing placeholder numbers. Check <span class="mono">WEB-INF/classes/db.properties</span> and confirm <span class="mono">ams_db</span> has been imported.</div>
  </div>
  <% } %>

  <div class="section">
    <div class="section-title">At a glance</div>
    <div class="stat-grid">
      <div class="stat-card stat-total">
        <div class="stat-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 3h-8a2 2 0 0 0-2 2v2h12V5a2 2 0 0 0-2-2Z"/></svg></div>
        <div class="figure"><%= totalAssets %></div>
        <div class="label">Total assets</div>
      </div>
      <div class="stat-card stat-assigned">
        <div class="stat-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21v-1a8 8 0 0 1 16 0v1"/></svg></div>
        <div class="figure"><%= inUse %></div>
        <div class="label">Assigned / in use</div>
      </div>
      <div class="stat-card stat-available">
        <div class="stat-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg></div>
        <div class="figure"><%= available %></div>
        <div class="label">Available</div>
      </div>
      <div class="stat-card stat-repair">
        <div class="stat-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94L3.3 23.3a2 2 0 0 1-2.83-2.83L10.66 10.3a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg></div>
        <div class="figure"><%= underRepair %></div>
        <div class="label">Under repair</div>
      </div>
      <div class="stat-card stat-warranty">
        <div class="stat-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg></div>
        <div class="figure"><%= expiredWarranty %></div>
        <div class="label">Warranty ending &le; 60 days</div>
      </div>
    </div>
  </div>

  <div class="form-grid" style="align-items:flex-start;">

    <!-- Category breakdown -->
    <div class="card full" style="grid-column:1 / span 1;">
      <div class="card-head">
        <div>
          <h2>Assets by category</h2>
          <div class="hint">Distribution of registered items across categories</div>
        </div>
        <a href="assets.jsp" class="btn btn-ghost btn-sm">View all</a>
      </div>
      <div class="card-pad">
        <% if (categoryBreakdown.isEmpty()) { %>
          <div class="empty-state">
            <h3>No assets registered yet</h3>
            <p>Add your first asset to see the category breakdown here.</p>
          </div>
        <% } else {
             int maxCount = 1;
             for (Map<String,Object> row : categoryBreakdown) {
                 maxCount = Math.max(maxCount, (Integer) row.get("count"));
             }
        %>
          <div style="display:flex; flex-direction:column; gap:.9rem;">
          <% for (Map<String,Object> row : categoryBreakdown) {
                int pct = (int) Math.round(((Integer) row.get("count")) * 100.0 / maxCount);
          %>
            <div>
              <div style="display:flex; justify-content:space-between; font-size:.85rem; margin-bottom:.35rem;">
                <span><%= row.get("name") %></span>
                <span class="mono" style="color:var(--ink-soft);"><%= row.get("count") %></span>
              </div>
              <div class="meter"><span style="width:<%= pct %>%; background:var(--brass);"></span></div>
            </div>
          <% } %>
          </div>
        <% } %>
      </div>
    </div>

    <!-- Warranty watch -->
    <div class="card full" style="grid-column:2 / span 1;">
      <div class="card-head">
        <div>
          <h2>Warranty watch</h2>
          <div class="hint">Items expiring within 60 days, or already expired</div>
        </div>
      </div>
      <div class="card-pad">
        <% if (warrantyWatch.isEmpty()) { %>
          <div class="empty-state">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
            <h3>All clear</h3>
            <p>No warranties are expiring soon.</p>
          </div>
        <% } else {
             for (Map<String,Object> row : warrantyWatch) {
                java.util.Date wd = (java.util.Date) row.get("warranty_expiry");
                boolean past = wd.before(new java.util.Date());
        %>
          <div style="display:flex; align-items:center; justify-content:space-between; padding:.6rem 0; border-bottom:1px solid var(--line);">
            <div>
              <div class="cell-primary"><%= row.get("asset_name") %></div>
              <div class="cell-sub"><span class="mono"><%= row.get("asset_id") %></span></div>
            </div>
            <span class="status <%= past ? "status-disposed" : "status-repair" %>">
              <%= past ? "Expired" : "Expires" %> <%= wd %>
            </span>
          </div>
        <% } } %>
      </div>
    </div>
  </div>

  <!-- Recent activity -->
  <div class="card section">
    <div class="card-head">
      <div>
        <h2>Recent activity</h2>
        <div class="hint">Latest entries from the audit trail</div>
      </div>
      <a href="reports.jsp" class="btn btn-ghost btn-sm">Open reports</a>
    </div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr><th>When</th><th>User</th><th>Action</th><th>Entity</th><th>Details</th></tr>
        </thead>
        <tbody>
          <% if (recentActivity.isEmpty()) { %>
          <tr><td colspan="5">
            <div class="empty-state">
              <h3>No activity yet</h3>
              <p>Actions like registering assets, issuing equipment, and logins will appear here.</p>
            </div>
          </td></tr>
          <% } else {
               for (Map<String,Object> row : recentActivity) {
          %>
          <tr>
            <td class="cell-sub"><%= row.get("created_at") %></td>
            <td><%= row.get("username") %></td>
            <td><span class="tag"><%= row.get("action") %></span></td>
            <td><%= row.get("entity") %> <span class="mono" style="color:var(--ink-soft);"><%= row.get("entity_id") != null ? row.get("entity_id") : "" %></span></td>
            <td class="cell-sub"><%= row.get("details") %></td>
          </tr>
          <% } } %>
        </tbody>
      </table>
    </div>
  </div>

<%@ include file="includes/footer.jsp" %>
