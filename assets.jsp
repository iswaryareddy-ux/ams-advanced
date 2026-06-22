<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String pageTitle = "Assets";
    String pageSubtitle = "Every item registered in the system, with status and assignment";
    String activePage = "assets";

    String flash = request.getParameter("flash");
    List<Map<String,Object>> assets = new ArrayList<>();
    List<String> categories = new ArrayList<>();
    boolean dbOk = true;

    try (Connection con = DBConnection.getConnection()) {

        try (PreparedStatement ps = con.prepareStatement("SELECT category_name FROM asset_categories ORDER BY category_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) categories.add(rs.getString("category_name"));
        }

        String sql = "SELECT a.asset_id, a.asset_name, c.category_name, a.serial_no, a.status, " +
                      "a.warranty_expiry, a.location, e.name AS assigned_name " +
                      "FROM assets a " +
                      "JOIN asset_categories c ON c.category_id = a.category_id " +
                      "LEFT JOIN employees e ON e.employee_id = a.assigned_to " +
                      "ORDER BY a.asset_id";

        try (PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                row.put("asset_id", rs.getString("asset_id"));
                row.put("asset_name", rs.getString("asset_name"));
                row.put("category_name", rs.getString("category_name"));
                row.put("serial_no", rs.getString("serial_no"));
                row.put("status", rs.getString("status"));
                row.put("warranty_expiry", rs.getDate("warranty_expiry"));
                row.put("location", rs.getString("location"));
                row.put("assigned_name", rs.getString("assigned_name"));
                assets.add(row);
            }
        }
    } catch (Exception ex) {
        dbOk = false;
    }
%>
<%@ include file="includes/header.jsp" %>

  <% if (!dbOk) { %>
  <div class="alert alert-info">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
    <div>Couldn't reach the database. Confirm the MySQL service is running and <span class="mono">db.properties</span> is configured correctly.</div>
  </div>
  <% } %>

  <% if ("added".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Asset registered successfully.</div>
  </div>
  <% } else if ("updated".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Asset details updated.</div>
  </div>
  <% } else if ("deleted".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Asset removed from the registry.</div>
  </div>
  <% } else if ("issued".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Asset issued to employee.</div>
  </div>
  <% } else if ("returned".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Asset returned and marked Available.</div>
  </div>
  <% } %>

  <div class="card">
    <div class="card-head">
      <div>
        <h2>Asset registry</h2>
        <div class="hint"><%= assets.size() %> asset<%= assets.size() == 1 ? "" : "s" %> on record</div>
      </div>
      <a href="asset_form.jsp" class="btn btn-accent">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Add asset
      </a>
    </div>

    <div class="toolbar">
      <div class="search">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input type="text" placeholder="Search by name, ID, serial or owner" data-table-search="assetsTable">
      </div>
      <select data-table-filter="assetsTable" data-col="2">
        <option value="">All categories</option>
        <% for (String c : categories) { %>
          <option value="<%= c %>"><%= c %></option>
        <% } %>
      </select>
      <select data-table-filter="assetsTable" data-col="4">
        <option value="">All statuses</option>
        <option value="Available">Available</option>
        <option value="In Use">In Use</option>
        <option value="Under Repair">Under Repair</option>
        <option value="Disposed">Disposed</option>
      </select>
    </div>

    <div class="table-wrap">
      <table id="assetsTable">
        <thead>
          <tr>
            <th>Asset ID</th>
            <th>Name</th>
            <th>Category</th>
            <th>Serial No.</th>
            <th>Status</th>
            <th>Assigned to</th>
            <th>Warranty</th>
            <th style="text-align:right;">Actions</th>
          </tr>
        </thead>
        <tbody>
        <% if (assets.isEmpty()) { %>
          <tr><td colspan="8">
            <div class="empty-state">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 3h-8a2 2 0 0 0-2 2v2h12V5a2 2 0 0 0-2-2Z"/></svg>
              <h3>No assets yet</h3>
              <p>Register your first asset to start tracking its lifecycle.</p>
            </div>
          </td></tr>
        <% } else {
            for (Map<String,Object> a : assets) {
              String status = (String) a.get("status");
              String statusClass = "status-available";
              if ("In Use".equals(status)) statusClass = "status-inuse";
              else if ("Under Repair".equals(status)) statusClass = "status-repair";
              else if ("Disposed".equals(status)) statusClass = "status-disposed";

              java.util.Date wd = (java.util.Date) a.get("warranty_expiry");
              boolean expired = wd != null && wd.before(new java.util.Date());
        %>
          <tr>
            <td><span class="tag"><%= a.get("asset_id") %></span></td>
            <td>
              <div class="cell-primary"><%= a.get("asset_name") %></div>
              <div class="cell-sub"><%= a.get("location") != null ? a.get("location") : "" %></div>
            </td>
            <td><%= a.get("category_name") %></td>
            <td class="mono cell-sub"><%= a.get("serial_no") != null ? a.get("serial_no") : "&mdash;" %></td>
            <td><span class="status <%= statusClass %>"><%= status %></span></td>
            <td><%= a.get("assigned_name") != null ? a.get("assigned_name") : "&mdash;" %></td>
            <td>
              <% if (wd == null) { %>
                <span class="cell-sub">&mdash;</span>
              <% } else { %>
                <span class="<%= expired ? "status status-disposed" : "cell-sub" %>"><%= wd %></span>
              <% } %>
            </td>
            <td>
              <div class="row-actions">
                <button class="icon-btn" title="Show QR code" data-open-modal="qrModal" data-asset-id="<%= a.get("asset_id") %>" data-asset-name="<%= a.get("asset_name") %>">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><line x1="14" y1="14" x2="14" y2="21"/><line x1="21" y1="14" x2="21" y2="21"/><line x1="14" y1="17.5" x2="21" y2="17.5"/></svg>
                </button>
                <a class="icon-btn" title="Edit" href="asset_form.jsp?id=<%= a.get("asset_id") %>">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.1 2.1 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </a>
                <% if ("Available".equals(status)) { %>
                  <a class="icon-btn" title="Issue to employee" href="asset_form.jsp?id=<%= a.get("asset_id") %>&action=issue">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" y1="8" x2="19" y2="14"/><line x1="16" y1="11" x2="22" y2="11"/></svg>
                  </a>
                <% } else if ("In Use".equals(status)) { %>
                  <form action="asset_action.jsp" method="post" style="display:inline;">
                    <input type="hidden" name="op" value="return">
                    <input type="hidden" name="asset_id" value="<%= a.get("asset_id") %>">
                    <button class="icon-btn" title="Mark returned">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg>
                    </button>
                  </form>
                <% } %>
                <form action="asset_action.jsp" method="post" style="display:inline;" data-confirm="Remove asset <%= a.get("asset_id") %> from the registry? This cannot be undone.">
                  <input type="hidden" name="op" value="delete">
                  <input type="hidden" name="asset_id" value="<%= a.get("asset_id") %>">
                  <button class="icon-btn danger" title="Delete">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
                  </button>
                </form>
              </div>
            </td>
          </tr>
        <% } } %>
        </tbody>
      </table>
    </div>
  </div>

  <!-- QR modal -->
  <div class="modal-backdrop" id="qrModal">
    <div class="modal">
      <div class="card-head">
        <h2>Asset QR code</h2>
        <button class="modal-close" data-close-modal aria-label="Close">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>
      <div class="card-pad" style="text-align:center;">
        <div id="qrCanvas" style="display:flex; justify-content:center; margin-bottom:1rem;"></div>
        <div class="qr-label cell-sub mono"></div>
        <p class="field help" style="margin-top:1rem;">Scan to look up this asset on a handheld device, or print this code onto a physical tag.</p>
      </div>
    </div>
  </div>

<%@ include file="includes/footer.jsp" %>
