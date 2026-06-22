<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String pageTitle = "Maintenance";
    String pageSubtitle = "Service history and open repair tickets for every asset";
    String activePage = "maintenance";

    String flash = request.getParameter("flash");
    List<Map<String,Object>> records = new ArrayList<>();
    boolean dbOk = true;

    try (Connection con = DBConnection.getConnection()) {
        String sql = "SELECT m.maintenance_id, m.asset_id, a.asset_name, m.issue_reported, m.service_date, " +
                      "m.completed_date, m.cost, m.status, m.remarks, v.vendor_name " +
                      "FROM maintenance m " +
                      "JOIN assets a ON a.asset_id = m.asset_id " +
                      "LEFT JOIN vendors v ON v.vendor_id = m.vendor_id " +
                      "ORDER BY m.service_date DESC, m.maintenance_id DESC";
        try (PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                row.put("maintenance_id", rs.getInt("maintenance_id"));
                row.put("asset_id", rs.getString("asset_id"));
                row.put("asset_name", rs.getString("asset_name"));
                row.put("issue_reported", rs.getString("issue_reported"));
                row.put("service_date", rs.getDate("service_date"));
                row.put("completed_date", rs.getDate("completed_date"));
                row.put("cost", rs.getBigDecimal("cost"));
                row.put("status", rs.getString("status"));
                row.put("remarks", rs.getString("remarks"));
                row.put("vendor_name", rs.getString("vendor_name"));
                records.add(row);
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
    <div>Couldn't reach the database. Confirm <span class="mono">db.properties</span> is configured correctly.</div>
  </div>
  <% } %>

  <% if ("added".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Maintenance ticket logged. Asset marked Under Repair.</div>
  </div>
  <% } else if ("updated".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Maintenance record updated.</div>
  </div>
  <% } else if ("completed".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Marked as completed. Asset returned to service.</div>
  </div>
  <% } else if ("deleted".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Maintenance record deleted.</div>
  </div>
  <% } %>

  <div class="card">
    <div class="card-head">
      <div>
        <h2>Maintenance history</h2>
        <div class="hint"><%= records.size() %> record<%= records.size() == 1 ? "" : "s" %></div>
      </div>
      <a href="maintenance_form.jsp" class="btn btn-accent">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Log new ticket
      </a>
    </div>

    <div class="toolbar">
      <div class="search">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input type="text" placeholder="Search by asset, vendor or issue" data-table-search="maintTable">
      </div>
      <select data-table-filter="maintTable" data-col="4">
        <option value="">All statuses</option>
        <option value="Open">Open</option>
        <option value="In Progress">In Progress</option>
        <option value="Completed">Completed</option>
      </select>
    </div>

    <div class="table-wrap">
      <table id="maintTable">
        <thead>
          <tr>
            <th>Asset</th>
            <th>Issue reported</th>
            <th>Service date</th>
            <th>Vendor</th>
            <th>Status</th>
            <th>Cost</th>
            <th style="text-align:right;">Actions</th>
          </tr>
        </thead>
        <tbody>
        <% if (records.isEmpty()) { %>
          <tr><td colspan="7">
            <div class="empty-state">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94L3.3 23.3a2 2 0 0 1-2.83-2.83L10.66 10.3a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>
              <h3>No maintenance records</h3>
              <p>Log a ticket when an asset needs repair or servicing.</p>
            </div>
          </td></tr>
        <% } else {
            for (Map<String,Object> m : records) {
              String status = (String) m.get("status");
              String statusClass = "status-repair";
              if ("Completed".equals(status)) statusClass = "status-available";
              else if ("Open".equals(status)) statusClass = "status-disposed";
        %>
          <tr>
            <td>
              <div class="cell-primary"><%= m.get("asset_name") %></div>
              <div class="cell-sub mono"><%= m.get("asset_id") %></div>
            </td>
            <td>
              <div><%= m.get("issue_reported") %></div>
              <% if (m.get("remarks") != null) { %><div class="cell-sub"><%= m.get("remarks") %></div><% } %>
            </td>
            <td class="cell-sub">
              <%= m.get("service_date") %>
              <% if (m.get("completed_date") != null) { %><div>Completed: <%= m.get("completed_date") %></div><% } %>
            </td>
            <td><%= m.get("vendor_name") != null ? m.get("vendor_name") : "&mdash;" %></td>
            <td><span class="status <%= statusClass %>"><%= status %></span></td>
            <td class="mono">&#8377;<%= m.get("cost") %></td>
            <td>
              <div class="row-actions">
                <% if (!"Completed".equals(status)) { %>
                <form action="maintenance_action.jsp" method="post" style="display:inline;" data-confirm="Mark this ticket as completed and return the asset to service?">
                  <input type="hidden" name="op" value="complete">
                  <input type="hidden" name="maintenance_id" value="<%= m.get("maintenance_id") %>">
                  <button class="icon-btn" title="Mark completed">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
                  </button>
                </form>
                <% } %>
                <a class="icon-btn" title="Edit" href="maintenance_form.jsp?id=<%= m.get("maintenance_id") %>">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.1 2.1 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </a>
                <form action="maintenance_action.jsp" method="post" style="display:inline;" data-confirm="Delete this maintenance record?">
                  <input type="hidden" name="op" value="delete">
                  <input type="hidden" name="maintenance_id" value="<%= m.get("maintenance_id") %>">
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

<%@ include file="includes/footer.jsp" %>
