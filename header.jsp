<%-- ============================================================
     includes/header.jsp
     Expects the calling page to set, before including this file:
       String pageTitle     (required)
       String pageSubtitle  (optional)
       String activePage    (optional - for sidebar highlighting)
     Performs a simple session-based auth guard: any page that
     includes this header is treated as a protected page and will
     redirect unauthenticated users to the login screen.
     ============================================================ --%>
<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    if (pageSubtitle == null) pageSubtitle = "";
    String role = (String) session.getAttribute("role");
    if (role == null) role = "User";
    String initials = "U";
    if (session.getAttribute("fullName") != null) {
        String fn = (String) session.getAttribute("fullName");
        String[] parts = fn.trim().split("\\s+");
        initials = parts[0].substring(0,1).toUpperCase();
        if (parts.length > 1) initials += parts[parts.length-1].substring(0,1).toUpperCase();
    }
%><!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= pageTitle %> &middot; AMS</title>
  <link rel="stylesheet" href="css/style.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
</head>
<body>
<div class="app">
  <%@ include file="sidebar.jsp" %>
  <div class="main">
    <header class="topbar">
      <div style="display:flex; align-items:center; gap:.85rem;">
        <button class="menu-btn" aria-label="Toggle menu">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
        </button>
        <div>
          <h1><%= pageTitle %></h1>
          <% if (!pageSubtitle.isEmpty()) { %><div class="subtitle"><%= pageSubtitle %></div><% } %>
        </div>
      </div>
      <div class="topbar-right">
        <div class="user-chip">
          <div class="user-avatar"><%= initials %></div>
          <span><%= session.getAttribute("fullName") != null ? session.getAttribute("fullName") : session.getAttribute("username") %> &middot; <%= role %></span>
        </div>
      </div>
    </header>
    <div class="content">
