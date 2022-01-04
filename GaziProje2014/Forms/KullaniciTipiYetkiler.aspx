<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="KullaniciTipiYetkiler.aspx.cs" Inherits="GaziProje2014.Forms.KullaniciTipiYetkiler" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" >  
    
    <div class="contentOrta00x40">
    <div class="contentOrtaSol250">
        <telerik:RadGrid ID="RadGridKullaniciTipleri" runat="server" Height="100%" Width="100%" CellSpacing="0"  AllowMultiRowSelection="false" OnSelectedIndexChanged="RadGridKullaniciTipleri_SelectedIndexChanged">     
            <ClientSettings EnableRowHoverStyle="true" EnablePostBackOnRowClick="true">
                <Selecting AllowRowSelect="true"></Selecting>
            </ClientSettings>
                     
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="KullaniciTipId">
                <Columns>
                    <telerik:GridBoundColumn DataField="KullaniciTipAdi" HeaderText="Kullanıcı Tipi" SortExpression="KullaniciTipAdi" UniqueName="KullaniciTipAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                </Columns>
            </MasterTableView>

        </telerik:RadGrid>
    </div>
    <div class="contentOrtaSag250">
        <telerik:RadGrid ID="grdYetkiler" runat="server" CellSpacing="-1"  GridLines="Both" OnItemDataBound="grdYetkiler_ItemDataBound">

            <ClientSettings EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True" />
            </ClientSettings>

            <MasterTableView AutoGenerateColumns="False" DataKeyNames="Id, KullaniciTipiId">
                
                <GroupByExpressions>
                    <telerik:GridGroupByExpression>                      
                        <SelectFields>                            
                            <telerik:GridGroupByField FieldAlias="PId" FieldName="PId">                                
                            </telerik:GridGroupByField>
                        </SelectFields>

                        <GroupByFields>                                                      
                            <telerik:GridGroupByField FieldName="PId">                               
                            </telerik:GridGroupByField>
                        </GroupByFields>                                                                        
                    </telerik:GridGroupByExpression>
                </GroupByExpressions>

                <Columns>
                    <telerik:GridBoundColumn DataField="Id" DataType="System.Int32" SortExpression="Id" UniqueName="Id" Display="false">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="PId" DataType="System.Int32" SortExpression="PId" UniqueName="PId" Display="false">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="KullaniciTipiId" DataType="System.Int32" SortExpression="KullaniciTipiId" UniqueName="KullaniciTipiId" Display="false">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="FormBaslik" SortExpression="FormBaslik" UniqueName="FormBaslik">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
<%--                    <telerik:GridCheckBoxColumn DataField="FormYetki" DataType="System.Boolean"  HeaderText="FormYetki" SortExpression="FormYetki" UniqueName="FormYetki">
                    </telerik:GridCheckBoxColumn>--%>

                    <telerik:GridTemplateColumn UniqueName="chkTemplateColumn" Reorderable="False" Groupable="False">
                        <ItemTemplate>
                            <asp:CheckBox ID="chkYetki"  runat="server" Font-Size="Large" AutoPostBack="False" Checked='<%# Convert.ToBoolean(Eval("FormYetki"))%>'></asp:CheckBox>
                        </ItemTemplate>
                        <HeaderStyle Width="70px"/>
                    </telerik:GridTemplateColumn>

                </Columns>

                <GroupHeaderTemplate>
                   <table>
                       <tr>
                           <td><asp:Image ID="imgResim" runat="server" /></td>
                           <td><asp:Label ID="lblBaslik" runat="server"  CssClass="YetkiBaslikYazi"></asp:Label></td>
                       </tr>
                   </table>                                 
                 </GroupHeaderTemplate>

            </MasterTableView>

        </telerik:RadGrid>
<%--        <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="Select F.Id, F.PId, F.FormBaslik, KF.FormYetki  from Formlar F
INNER JOIN KullaniciFormlar KF ON  KF.FormId = F.Id 
Where KF.KullaniciTipiId = 1 And PId IS NOT NULL"></asp:SqlDataSource>--%>
    </div>
    </div>
    </telerik:RadAjaxPanel>

    <div class="contentAlt30">
        <telerik:RadButton Width="150px" ID="btnKaydet" runat="server" Text="Kaydet" OnClick="btnKaydet_Click"></telerik:RadButton>   
    </div>
    <div class="contentAlt30Golge"> 
    </div>
    

    <telerik:RadNotification ID="RadNotification1" runat="server" EnableRoundedCorners="true"
        EnableShadow="true" Text="" Title="Bilgilendirme" Width="300" Height="100">
    </telerik:RadNotification>


</asp:Content>
