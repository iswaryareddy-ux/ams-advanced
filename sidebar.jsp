<%-- ============================================================
     includes/sidebar.jsp
     Expects (optional) String activePage set by the calling page
     before the include, e.g. activePage = "assets";
     ============================================================ --%>
<%
    if (activePage == null) activePage = "";
%>
<nav class="sidebar" aria-label="Main navigation">
  <div class="brand">
    <div class="brand-mark">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>
    </div>
    <div class="brand-text">
      <strong>AMS</strong>
      <span>Asset Manager</span>
    </div>
  </div>

  <div class="nav">
    <div class="nav-label">Overview</div>
    <a href="dashboard.jsp" class="<%= activePage.equals("dashboard") ? "active" : "" %>">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9" rx="1"/><rect x="14" y="3" width="7" height="5" rx="1"/><rect x="14" y="12" width="7" height="9" rx="1"/><rect x="3" y="16" width="7" height="5" rx="1"/></svg>
      Dashboard
    </a>

    <div class="nav-label">Registry</div>
    <a href="assets.jsp" class="<%= activePage.equals("assets") ? "active" : "" %>">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 3h-8a2 2 0 0 0-2 2v2h12V5a2 2 0 0 0-2-2Z"/></svg>
      Assets
    </a>
    <a href="employees.jsp" class="<%= activePage.equals("employees") ? "active" : "" %>">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21v-1a8 8 0 0 1 16 0v1"/></svg>
      Employees
    </a>
    <a href="vendors.jsp" class="<%= activePage.equals("vendors") ? "active" : "" %>">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9 12 3l9 6"/><path d="M5 9v11h14V9"/><path d="M9 20v-6h6v6"/></svg>
      Vendors
    </a>

    <div class="nav-label">Operations</div>
    <a href="maintenance.jsp" class="<%= activePage.equals("maintenance") ? "active" : "" %>">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94L3.3 23.3a2 2 0 0 1-2.83-2.83L10.66 10.3a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>
      Maintenance
    </a>
    <a href="reports.jsp" class="<%= activePage.equals("reports") ? "active" : "" %>">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 16v-5"/><path d="M12 16V8"/><path d="M17 16v-3"/></svg>
      Reports
    </a>
  </div>

  <div class="sidebar-foot">
    Signed in as<br>
    <a href="logout.jsp" title="Sign out">
      <%
        String fullName = "Guest";
        if (session.getAttribute("fullName") != null) {
            fullName = (String) session.getAttribute("fullName");
        }
      %>
      <%= fullName %> &middot; Sign out
    </a>
  </div>
</nav>
