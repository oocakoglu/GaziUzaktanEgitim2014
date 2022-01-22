<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="Tercihler.aspx.cs" Inherits="GaziProje2014.Forms.Tercihler" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <style>
        .Arkaplanlar{
            padding:10px;
        }
        .fieldler{
            /*opacity: 0.8; 
            filter: alpha(opacity=80);*/
        }

    </style>

        <telerik:RadListView runat="server" ID="grdThemes" 
            AllowPaging="true" PageSize="30"  
            OnNeedDataSource="grdThemes_NeedDataSource">

                <LayoutTemplate>
                    <div class="Arkaplanlar">
                      <fieldset class="fieldler">
                            <legend class="legendForm">Arkaplanlar</legend>  
                            <asp:Panel ID="itemPlaceholder" runat="server">
                            </asp:Panel>
    <%--                        <div style="clear: both;">
                            </div>--%>
                      </fieldset>
                    </div>
                </LayoutTemplate>
                <ItemTemplate>
                    <div style="float: left; margin: 5px; padding: 2px; position: relative;"
                        class="myClass">
                        <fieldset>
                            <legend class="legendForm">Tema Bir</legend>
                            <asp:Label ID="lblTemaPath" runat="server" Text='<%# Eval("TemaPath") %>' Visible="false" />  
                            <asp:Image ID="imgSoruResim" runat="server" ImageUrl='<%# Eval("TemaThumbnailPath") %>' /><br />
                            <telerik:RadButton ID="btnTemaUygula" runat="server" Text="Uygula"  OnClick="btnTemaUygula_Click"></telerik:RadButton>
                        </fieldset>
                    </div>
                </ItemTemplate>

        </telerik:RadListView>


</asp:Content>
