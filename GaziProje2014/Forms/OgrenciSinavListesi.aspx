<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="OgrenciSinavListesi.aspx.cs" Inherits="GaziProje2014.Forms.OgrenciSinavListesi" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" >      
    <div class="contentUst40">
        <table class="tdTablo">
            <tr>
                <td class="tdCellBaslik">Sınav Adı :</td>
                <td class="tdCellIcerik"><telerik:RadTextBox ID="txtSinavAdi" runat="server"></telerik:RadTextBox></td>
                <td class="tdCellBaslik">Ders Adı :</td>
                <td class="tdCellIcerik"><telerik:RadTextBox ID="txtDersAdi" runat="server"></telerik:RadTextBox></td>       
                <td class="tdCellBaslik">  
                <telerik:RadButton ID="btnSorgula" runat="server" Text="Sorgula" OnClick="btnSorgula_Click">
                </telerik:RadButton> 
                </td>                                                           
            </tr>
        </table>
    </div>
    <div class="contentUst40Golge">
    </div>

    <div class="contentOrta40x40">       
        <telerik:RadGrid ID="grdSinavlar" runat="server" CellSpacing="-1"  GridLines="Both">
            <ClientSettings EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="SinavId">
                <Columns>
                      
                    <telerik:GridBoundColumn DataField="SinavId" DataType="System.Int32" UniqueName="SinavId" Display="false">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridTemplateColumn SortExpression="DersAdi" UniqueName="TemplateClmnYonetici" HeaderText="Ders Adi">
                        <ItemTemplate>                                  
                            <asp:Label ID="lblYoneticiOnayi" runat="server" Text='<%# Eval("DersAdi") ==null ? "Genel Sınav" : Eval("DersAdi") %>'></asp:Label>
                        </ItemTemplate>
                    </telerik:GridTemplateColumn>
                    
<%--                    <telerik:GridBoundColumn DataField="DersAdi"  HeaderText="Ders Adi" SortExpression="DersAdi" UniqueName="DersAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>--%>

                    <telerik:GridBoundColumn DataField="SinavAdi"  HeaderText="Sınav Adı" SortExpression="SinavAdi" UniqueName="SinavAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="BaslangicTarihi"  HeaderText="Baslangic Tarihi" SortExpression="BaslangicTarihi" UniqueName="BaslangicTarihi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="BitisTarihi"  HeaderText="Bitis Tarihi" SortExpression="BitisTarihi" UniqueName="BitisTarihi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                </Columns>
            </MasterTableView>
        </telerik:RadGrid>    
    </div>   
    </telerik:RadAjaxPanel>
         
    <div class="contentAlt30">
        <telerik:RadButton Width="100px" ID="btnSinavaGir" runat="server" Text="Sınava Gir" OnClick="btnSinavaGir_Click"></telerik:RadButton>     
    </div>
    <div class="contentAlt30Golge"> 
    </div>

    
    <telerik:RadNotification ID="RadNotification1" runat="server" EnableRoundedCorners="true"
        EnableShadow="true" Text="Sample content" Title="Bilgilendirme" Width="300" Height="100">
    </telerik:RadNotification>






</asp:Content>
