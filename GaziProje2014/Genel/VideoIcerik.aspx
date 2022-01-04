<%@ Page Title="" Language="C#" MasterPageFile="~/PublicSite.Master" AutoEventWireup="true" CodeBehind="VideoIcerik.aspx.cs" Inherits="GaziProje2014.Genel.VideoIcerik" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
    <script>
    $(document).ready(function() {
        $('.kare').hide();	
    });
    function goster()
	    {
		    $('.kare').slideToggle(1000);		
	    }
    </script>



    <div runat="server" class="OtherFile" id="pnlvideo">         

    </div>

    <div class="solAltKose">
        <asp:imagebutton runat="server" Id="btnInformation" ImageUrl="~/Style/information.png" OnClientClick="goster(); return false;"></asp:imagebutton>
    </div>


    <div class="kare">
        <div id="kareIcerik" runat="server">
        </div>
        <asp:imagebutton runat="server" Id="btnClose" ImageUrl="~/Style/Closebutton.png" OnClientClick="goster(); return false;"></asp:imagebutton>
    </div>   



</asp:Content>
