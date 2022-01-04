<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="Sinav.aspx.cs" Inherits="GaziProje2014.Forms.Sinav" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
 
<style>
    .legendForm {
        padding: 4px;
        position: absolute;
        left: 10px;
        top: -11px;
        background-color: #2DABC1; /*#4F709F;*/
        color: white;
        -webkit-border-radius: 4px;
        -moz-border-radius: 4px;
        border-radius: 4px;
        box-shadow: 2px 2px 4px #888;
        -moz-box-shadow: 2px 2px 4px #888;
        -webkit-box-shadow: 2px 2px 4px #888;
        text-shadow: 1px 1px 1px #333;
    }

    .fieldsetForm {
        position: relative;
        padding: 10px;                
        margin-bottom: 30px;
        background: #F6F6F6;
        -webkit-border-radius: 8px;
        -moz-border-radius: 8px;
        border-radius: 8px;
        background: -webkit-gradient(linear, left top, left bottom, from(#EFEFEF), to(#FFFFFF));
        background: -moz-linear-gradient(center top, #EFEFEF, #FFFFFF 100%);
        box-shadow: 3px 3px 10px #ccc;
        -moz-box-shadow: 3px 3px 10px #ccc;
        -webkit-box-shadow: 3px 3px 10px #ccc;
    }
</style>

            <telerik:RadListView ID="RadListView1" runat="server" DataKeyNames="SoruId" DataSourceID="SqlDataSource1" Skin="Silk" OnItemDataBound="RadListView1_ItemDataBound">
                <LayoutTemplate>
                    <div style="width:800px;">
                        <ul>
                            <li id="itemPlaceholder" runat="server"></li>                            
                        </ul>
                        <p></p>
                        <div>
                            <telerik:RadButton ID="btnSinaviBitir" runat="server" Text="Bitir"  OnClick="btnSinaviBitir_Click"></telerik:RadButton>
                        </div>
                        <div style="display: none">
                            <telerik:RadCalendar ID="rlvSharedCalendar" runat="server" RangeMinDate="<%#new DateTime(1900, 1, 1) %>" Skin="<%#Container.Skin %>" />
                        </div>
                        <div style="display: none">
                            <telerik:RadTimeView ID="rlvSharedTimeView" runat="server" Skin="<%# Container.Skin %>" />
                        </div>
                    </div>
                </LayoutTemplate>
                <ItemTemplate>
                  
                        <fieldset class="fieldsetForm">
                            <p>
                            <legend class="legendForm">Soru Bir</legend>
<%--                             <a href='<%# "ResimGoruntule.aspx?ResimAdi=images/"+ Eval("DogruCvp")+ "&genislik=599" %>' title=""><%# Eval("DogruCvp") %></a>--%>                                                     
                            <asp:Image ID="imgSoruResim" runat="server" ImageUrl='<%# Eval("SoruResmi") %>' />                     
                            &nbsp;<asp:Label ID="SoruLabel" runat="server" Text='<%# Eval("SoruMetni") %>' />
                            &nbsp;<asp:Label ID="IdLabel" runat="server" Text='<%# Eval("SoruId") %>' Visible="false" />
                            </p>
                            <asp:RadioButtonList ID="rblCvp" runat="server">
                            </asp:RadioButtonList>
                        </fieldset>
                 
                </ItemTemplate>
                <EmptyDataTemplate>
                    <div class="RadListView RadListView_Office2010Black">
                        <div class="rlvEmpty">
                            Burada gösterebilecek veri Yok.
                        </div>
                    </div>
                </EmptyDataTemplate>
            </telerik:RadListView>


<%--            <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="Select SoruId, SoruSira, SoruMetni, SoruResmi, Cevap from SinavSorular"></asp:SqlDataSource>--%>

</asp:Content>
