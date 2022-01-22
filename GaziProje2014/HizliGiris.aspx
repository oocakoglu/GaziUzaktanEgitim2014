<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="HizliGiris.aspx.cs" Inherits="GaziProje2014.HizliGiris" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
        
     <telerik:RadGrid ID="grdKullanici" runat="server" CellSpacing="-1"       
         OnNeedDataSource="grdKullanici_NeedDataSource"
         GridLines="Both" AllowMultiRowSelection="false">
            <ClientSettings>
                <Selecting AllowRowSelect="True" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="KullaniciId,KullaniciTipId, KullaniciAdi">
                <Columns>
                    <telerik:GridBoundColumn DataField="KullaniciId" DataType="System.Int32" FilterControlAltText="Filter KullaniciId column" HeaderText="KullaniciId" ReadOnly="True" SortExpression="KullaniciId" UniqueName="KullaniciId">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="KullaniciTipId" DataType="System.Int32" FilterControlAltText="Filter KullaniciTipId column" HeaderText="KullaniciTipId" ReadOnly="True" SortExpression="KullaniciTipId" UniqueName="KullaniciTipId">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="KullaniciAdi" FilterControlAltText="Filter KullaniciAdi column" HeaderText="KullaniciAdi" SortExpression="KullaniciAdi" UniqueName="KullaniciAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="KullaniciTipAdi" FilterControlAltText="Filter KullaniciTipAdi column" HeaderText="KullaniciTipAdi" SortExpression="KullaniciTipAdi" UniqueName="KullaniciTipAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="Adi" FilterControlAltText="Filter Adi column" HeaderText="Adi" SortExpression="Adi" UniqueName="Adi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="Soyadi" FilterControlAltText="Filter Soyadi column" HeaderText="Soyadi" SortExpression="Soyadi" UniqueName="Soyadi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                </Columns>
            </MasterTableView>
        </telerik:RadGrid>
        
        <asp:Button ID="btnAdmin" runat="server" OnClick="btnAdmin_Click" Text="Admin" />       
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server"></telerik:RadScriptManager>

    </div>
    </form>
</body>
</html>
