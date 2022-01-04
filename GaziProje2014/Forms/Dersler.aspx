<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="Dersler.aspx.cs" Inherits="GaziProje2014.Forms.Dersler" %>
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
     <telerik:RadGrid ID="RadGrid1" AllowAutomaticUpdates="True" AllowAutomaticDeletes="True"
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
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="DersId" DataSourceID="SqlDataSource1" CommandItemDisplay="Top">
                <CommandItemTemplate>                
                    <telerik:RadButton Width="100px" ID="btnYeniEkle" runat="server" Text="Yeni Ekle" CommandName="InitInsert"></telerik:RadButton>         
                    <telerik:RadButton Width="100px" ID="btnDuzenle" runat="server" Text="Düzenle" CommandName="EditSelected"></telerik:RadButton>         
                    <telerik:RadButton Width="100px" ID="btnSil" runat="server" Text="Sil" CommandName="DeleteSelected"></telerik:RadButton>                               
                </CommandItemTemplate>
                <Columns>
                    <telerik:GridBoundColumn DataField="DersId" DataType="System.Int32" FilterControlAltText="Filter DersId column" HeaderText="DersId" ReadOnly="True" SortExpression="DersId" UniqueName="DersId">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="DersAdi" FilterControlAltText="Filter DersAdi column" HeaderText="DersAdi" SortExpression="DersAdi" UniqueName="DersAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="DersAciklama" FilterControlAltText="Filter DersAciklama column" HeaderText="DersAciklama" SortExpression="DersAciklama" UniqueName="DersAciklama">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    <telerik:GridCheckBoxColumn DataField="DersDurum" DataType="System.Boolean" FilterControlAltText="Filter DersDurum column" HeaderText="DersDurum" SortExpression="DersDurum" UniqueName="DersDurum">
                    </telerik:GridCheckBoxColumn>
                </Columns>
            </MasterTableView>
        </telerik:RadGrid>

    </div>    
    <div class="contentAlt30">         
<%--        <telerik:RadButton Width="100px" ID="btnYeniEkle" runat="server" Text="Yeni Ekle" CommandName="InitInsert"></telerik:RadButton>         
        <telerik:RadButton Width="100px" ID="btnDuzenle" runat="server" Text="Düzenle" CommandName="EditSelected"></telerik:RadButton>         
        <telerik:RadButton Width="100px" ID="btnSil" runat="server" Text="Sil" CommandName="DeleteSelected"></telerik:RadButton>  
        <asp:LinkButton ID="btnEditSelected" runat="server" CommandName="EditSelected" Visible='<%# RadGrid1.EditIndexes.Count == 0 %>'></asp:LinkButton>--%>
         
    </div>
    <div class="contentAlt30Golge"> 
    </div>


    <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>"
        SelectCommand="SELECT [DersId], [DersAdi], [DersAciklama], [DersDurum] FROM [Dersler]"
        DeleteCommand="DELETE FROM [Dersler] WHERE [DersId] = @DersId"
        InsertCommand="INSERT INTO [Dersler] ([DersAdi], [DersAciklama], [DersDurum]) VALUES (@DersAdi, @DersAciklama, @DersDurum)"
        UpdateCommand="UPDATE [Dersler] SET [DersAdi] = @DersAdi, [DersAciklama] = @DersAciklama, [DersDurum] = @DersDurum WHERE [DersId] = @DersId">
        <DeleteParameters>
            <asp:Parameter Name="DersId" Type="Int32" />
        </DeleteParameters>
        <InsertParameters>
            <asp:Parameter Name="DersAdi" Type="String" />
            <asp:Parameter Name="DersAciklama" Type="String" />
            <asp:Parameter Name="DersDurum" Type="Boolean" />
        </InsertParameters>
        <UpdateParameters>
            <asp:Parameter Name="DersAdi" Type="String" />
            <asp:Parameter Name="DersAciklama" Type="String" />
            <asp:Parameter Name="DersDurum" Type="Boolean" />
            <asp:Parameter Name="DersId" Type="Int32" />
        </UpdateParameters>
    </asp:SqlDataSource>

</asp:Content>
