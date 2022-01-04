<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="KullaniciTipleri.aspx.cs" Inherits="GaziProje2014.Forms.KullaniciTipleri" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <div class="contentUst40">
        <table class="tdTablo">
            <tr>
                <td class="tdCellBaslik">Ders Adı :</td>
                <td class="tdCellIcerik"><telerik:RadTextBox ID="txtDersAdi" runat="server"></telerik:RadTextBox></td>  
                <td>        
                <telerik:RadButton ID="RadButton1" runat="server" Text="Sorgula">
                </telerik:RadButton> 
                </td>                                                           
            </tr>
        </table>
    </div>
    <div class="contentUst40Golge">
    </div>

    <div class="contentOrta40x40">         
     <telerik:RadGrid ID="RadGrid1" AllowAutomaticUpdates="true" AllowAutomaticDeletes="true"
            DataSourceID="SqlDataSource1" AllowSorting="True" 
              runat="server" AllowMultiRowSelection="True" 
            AllowMultiRowEdit="True" AllowAutomaticInserts="True">           
               <ExportSettings>
                <Pdf PageWidth="">
                </Pdf>
            </ExportSettings>
            <ClientSettings EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="KullaniciTipId" DataSourceID="SqlDataSource1" CommandItemDisplay="Top">
                <CommandItemTemplate>                
                    <telerik:RadButton Width="100px" ID="btnYeniEkle" runat="server" Text="Yeni Ekle" CommandName="InitInsert"></telerik:RadButton>         
                    <telerik:RadButton Width="100px" ID="btnDuzenle" runat="server" Text="Düzenle" CommandName="EditSelected"></telerik:RadButton>         
                    <telerik:RadButton Width="100px" ID="btnSil" runat="server" Text="Sil" CommandName="DeleteSelected"></telerik:RadButton>                
                </CommandItemTemplate>
                <Columns>
                    <telerik:GridBoundColumn DataField="KullaniciTipId" DataType="System.Int32" FilterControlAltText="Filter KullaniciTipId column" HeaderText="KullaniciTipId" ReadOnly="True" SortExpression="KullaniciTipId" UniqueName="KullaniciTipId">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="KullaniciTipAdi" FilterControlAltText="Filter KullaniciTipAdi column" HeaderText="KullaniciTipAdi" SortExpression="KullaniciTipAdi" UniqueName="KullaniciTipAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="KullaniciTipAciklama" FilterControlAltText="Filter KullaniciTipAciklama column" HeaderText="KullaniciTipAciklama" SortExpression="KullaniciTipAciklama" UniqueName="KullaniciTipAciklama">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    <telerik:GridCheckBoxColumn DataField="KullaniciTipDurum" DataType="System.Boolean" FilterControlAltText="Filter KullaniciTipDurum column" HeaderText="KullaniciTipDurum" SortExpression="KullaniciTipDurum" UniqueName="KullaniciTipDurum">
                    </telerik:GridCheckBoxColumn>
                </Columns>
            </MasterTableView>
        </telerik:RadGrid>

    </div>
        
    <div class="contentAlt30">       
    </div>
    <div class="contentAlt30Golge"> 
    </div>


    <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>"
        SelectCommand="SELECT [KullaniciTipId], [KullaniciTipAdi], [KullaniciTipAciklama], [KullaniciTipDurum] FROM [KullaniciTipleri]"
        DeleteCommand="DELETE FROM [KullaniciTipleri] WHERE [KullaniciTipId] = @KullaniciTipId"
        InsertCommand="INSERT INTO [KullaniciTipleri] ([KullaniciTipAdi], [KullaniciTipAciklama], [KullaniciTipDurum]) VALUES (@KullaniciTipAdi, @KullaniciTipAciklama, @KullaniciTipDurum)"
        UpdateCommand="UPDATE [KullaniciTipleri] SET [KullaniciTipAdi] = @KullaniciTipAdi, [KullaniciTipAciklama] = @KullaniciTipAciklama, [KullaniciTipDurum] = @KullaniciTipDurum WHERE [KullaniciTipId] = @KullaniciTipId">
        <DeleteParameters>
            <asp:Parameter Name="KullaniciTipId" Type="Int32" />
        </DeleteParameters>
        <InsertParameters>
            <asp:Parameter Name="KullaniciTipAdi" Type="String" />
            <asp:Parameter Name="KullaniciTipAciklama" Type="String" />
            <asp:Parameter Name="KullaniciTipDurum" Type="Boolean" />
        </InsertParameters>
        <UpdateParameters>
            <asp:Parameter Name="KullaniciTipAdi" Type="String" />
            <asp:Parameter Name="KullaniciTipAciklama" Type="String" />
            <asp:Parameter Name="KullaniciTipDurum" Type="Boolean" />
            <asp:Parameter Name="KullaniciTipId" Type="Int32" />
        </UpdateParameters>
    </asp:SqlDataSource>




</asp:Content>
