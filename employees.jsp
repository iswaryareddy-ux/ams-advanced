<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String pageTitle = "Employees";
    String pageSubtitle = "Everyone who can be issued company assets";
    String activePage = "employees";

    String flash = request.getParameter("flash");
    List<Map<String,Object>> employees = new ArrayList<>();
    boolean dbOk = true;

    try (Connection con = DBConnection.getConnection()) {
        String sql = "SELECT e.employee_id, e.name, e.department, e.designation, e.phone, e.email, e.status, " +
                      "(SELECT COUNT(*) FROM assets a WHERE a.assigned_to = e.employee_id AND a.status = 'In Use') AS asset_count " +
                      "FROM employees e ORDER BY e.name";
        try (PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                row.put("employee_id", rs.getInt("employee_id"));
                row.put("name", rs.getString("name"));
                row.put("department", rs.getString("department"));
                row.put("designation", rs.getString("designation"));
                row.put("phone", rs.getString("phone"));
                row.put("email", rs.getString("email"));
                row.put("status", rs.getString("status"));
                row.put("asset_count", rs.getInt("asset_count"));
                employees.add(row);
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
    <div>Employee added.</div>
  </div>
  <% } else if ("updated".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Employee details updated.</div>
  </div>
  <% } else if ("deleted".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Employee removed.</div>
  </div>
  <% } else if ("blocked".equals(flash)) { %>
  <div class="alert alert-error">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
    <div>This employee still has assets assigned. Return all assets before removing them.</div>
  </div>
  <% } %>

  <div class="card">
    <div class="card-head">
      <div>
        <h2>Employee directory</h2>
        <div class="hint"><%= employees.size() %> employee<%= employees.size() == 1 ? "" : "s" %> on record</div>
      </div>
      <a href="employee_form.jsp" class="btn btn-accent">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Add employee
      </a>
    </div>

    <div class="toolbar">
      <div class="search">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input type="text" placeholder="Search by name, department or email" data-table-search="empTable">
      </div>
      <select data-table-filter="empTable" data-col="5">
        <option value="">All statuses</option>
        <option value="Active">Active</option>
        <option value="Inactive">Inactive</option>
      </select>
    </div>

    <div class="table-wrap">
      <table id="empTable">
        <thead>
          <tr>
            <th>Name</th>
            <th>Department</th>
            <th>Designation</th>
            <th>Contact</th>
            <th>Assets issued</th>
            <th>Status</th>
            <th style="text-align:right;">Actions</th>
          </tr>
        </thead>
        <tbody>
        <% if (employees.isEmpty()) { %>
          <tr><td colspan="7">
            <div class="empty-state">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21v-1a8 8 0 0 1 16 0v1"/></svg>
              <h3>No employees yet</h3>
              <p>Add employees so assets can be issued to them.</p>
            </div>
          </td></tr>
        <% } else {
            for (Map<String,Object> e : employees) {
              boolean active = "Active".equals(e.get("status"));
        %>
          <tr>
            <td>
              <div class="cell-primary"><%= e.get("name") %></div>
              <div class="cell-sub"><%= e.get("email") != null ? e.get("email") : "" %></div>
            </td>
            <td><%= e.get("department") != null ? e.get("department") : "&mdash;" %></td>
            <td><%= e.get("designation") != null ? e.get("designation") : "&mdash;" %></td>
            <td class="cell-sub"><%= e.get("phone") != null ? e.get("phone") : "&mdash;" %></td>
            <td><span class="tag"><%= e.get("asset_count") %> active</span></td>
            <td><span class="status <%= active ? "status-available" : "status-disposed" %>"><%= e.get("status") %></span></td>
            <td>
              <div class="row-actions">
                <a class="icon-btn" title="Edit" href="employee_form.jsp?id=<%= e.get("employee_id") %>">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.1 2.1 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </a>
                <form action="employee_action.jsp" method="post" style="display:inline;" data-confirm="Remove <%= e.get("name") %> from the directory?">
                  <input type="hidden" name="op" value="delete">
                  <input type="hidden" name="employee_id" value="<%= e.get("employee_id") %>">
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
