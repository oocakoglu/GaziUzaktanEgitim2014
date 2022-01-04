<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="tolga_Sinav_Detay.aspx.cs" Inherits="GaziProje2014.Pages.tolga_Sinav_Detay" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server">
            <Scripts>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.Core.js"></asp:ScriptReference>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.jQuery.js"></asp:ScriptReference>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.jQueryInclude.js"></asp:ScriptReference>
            </Scripts>
        </telerik:RadScriptManager>
        <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        </telerik:RadAjaxManager>
        <div>
            <telerik:RadGrid ID="gridHazirSinavlar" runat="server" DataSourceID="sqlHazirSinav" OnItemCommand="gridHazirSinavlar_ItemCommand" Width="446px">
                <ExportSettings>
                    <Pdf PageWidth="">
                    </Pdf>
                </ExportSettings>
                <ClientSettings AllowKeyboardNavigation="true" EnablePostBackOnRowClick="true">
                    <Selecting AllowRowSelect="true"></Selecting>
                </ClientSettings>
                <MasterTableView AutoGenerateColumns="False" DataKeyNames="Id" DataSourceID="sqlHazirSinav">
                    <RowIndicatorColumn Visible="False">
                    </RowIndicatorColumn>
                    <ExpandCollapseColumn Created="True">
                    </ExpandCollapseColumn>
                    <Columns>
                        <telerik:GridBoundColumn DataField="Id" DataType="System.Int64" Display="False" FilterControlAltText="Filter Id column" HeaderText="Id" ReadOnly="True" SortExpression="Id" UniqueName="Id">
                            <ColumnValidationSettings>
                                <ModelErrorMessage Text="" />
                            </ColumnValidationSettings>
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="KullaniciId" DataType="System.Int32" Display="False" FilterControlAltText="Filter KullaniciId column" HeaderText="KullaniciId" SortExpression="KullaniciId" UniqueName="KullaniciId">
                            <ColumnValidationSettings>
                                <ModelErrorMessage Text="" />
                            </ColumnValidationSettings>
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="SinavAdi" FilterControlAltText="Filter SinavAdi column" HeaderText="SinavAdi" SortExpression="SinavAdi" UniqueName="SinavAdi">
                            <ColumnValidationSettings>
                                <ModelErrorMessage Text="" />
                            </ColumnValidationSettings>
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="KayitTrh" DataType="System.DateTime" FilterControlAltText="Filter KayitTrh column" HeaderText="KayitTrh" SortExpression="KayitTrh" UniqueName="KayitTrh">
                            <ColumnValidationSettings>
                                <ModelErrorMessage Text="" />
                            </ColumnValidationSettings>
                        </telerik:GridBoundColumn>
                        <telerik:GridButtonColumn CommandName="Detay" FilterControlAltText="Filter Detay column" Text="Detay" UniqueName="Detay">
                        </telerik:GridButtonColumn>
                    </Columns>
                </MasterTableView>
            </telerik:RadGrid>
            <telerik:RadListView ID="RadListView1" runat="server" AllowPaging="True" DataSourceID="sqlSinavDetay" Width="350px">
                <LayoutTemplate>
                    <div class="RadListView RadListView_Default">
                        <table cellspacing="0" >
                            <thead>
                                <tr class="rlvHeader">
                                    <th>Soru</th>
                                    <th>ResimSoru</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr id="itemPlaceholder" runat="server">
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </LayoutTemplate>
                <ItemTemplate>
                    <tr class="rlvI">
                        <td>
                            <asp:Label ID="SoruLabel" runat="server" Text='<%# Eval("Soru") %>' />
                        </td>
                        <td>
                            <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("ResimSoru") %>' />
                        </td>
                    </tr>
                </ItemTemplate>
                <AlternatingItemTemplate>
                    <tr class="rlvA">
                        <td>
                            <asp:Label ID="SoruLabel" runat="server" Text='<%# Eval("Soru") %>' />
                        </td>
                        <td>
                            <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("ResimSoru") %>' />
                        </td>
                    </tr>
                </AlternatingItemTemplate>
                <EmptyDataTemplate>
                    <div class="RadListView RadListView_Default">
                        <div class="rlvEmpty">
                            There are no items to be displayed.
                        </div>
                    </div>
                </EmptyDataTemplate>
                <SelectedItemTemplate>
                    <tr class="rlvISel">
                        <td>
                            <asp:Label ID="SoruLabel" runat="server" Text='<%# Eval("Soru") %>' />
                        </td>
                        <td>
                            <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("ResimSoru") %>' />
                        </td>
                    </tr>
                </SelectedItemTemplate>
            </telerik:RadListView>
            <asp:SqlDataSource ID="sqlHazirSinav" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="SELECT [Id], [KullaniciId], [SinavAdi], [KayitTrh] FROM [Sinav] ORDER BY [KayitTrh] DESC, [SinavAdi] ASC"></asp:SqlDataSource>
            <asp:SqlDataSource ID="sqlSinavDetay" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>"
                SelectCommand="SELECT Sorular.Soru, Sorular.ResimSoru FROM Sinav_Detay INNER JOIN Sorular ON Sinav_Detay.SorularId = Sorular.Id WHERE (Sinav_Detay.SinavId = @SinavId)">
                <SelectParameters>
                    <asp:ControlParameter ControlID="gridHazirSinavlar" Name="SinavId" PropertyName="SelectedValue" />
                </SelectParameters>
            </asp:SqlDataSource>
            <br />
        </div>
    </form>
</body>
</html>
