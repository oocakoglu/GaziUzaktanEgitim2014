<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="KullaniciTipiYetkileri.aspx.cs" Inherits="GaziProje2014.Forms.KullaniciTipiYetkileri" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <style>
        .DuyuruOrtaSol {
            position: absolute;
            top: 0px;
            left: 0px;
            bottom: 0px;
            width: 250px;
            background-color:green;
        }

        .DuyuruOrtaGovde {
            position: absolute;
            top: 0px;
            left: 250px;
            bottom: 0px;
            right: 0px;
            background-color: gray;
        }
    </style>



    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" >  
    <div class="DuyuruOrtaSol">
        <telerik:RadGrid ID="RadGridKullaniciTipleri" runat="server" Height="100%" Width="100%" CellSpacing="0" 
            DataSourceID="SqlKullaniciTipleri"
            AllowMultiRowSelection="false" OnDataBound="RadGridKullaniciTipleri_DataBound" OnItemDataBound="RadGridKullaniciTipleri_ItemDataBound">
                            
            <ClientSettings EnablePostBackOnRowClick="true">
                <Selecting AllowRowSelect="true"></Selecting>
            </ClientSettings>
                     
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="KullaniciTipId" DataSourceID="SqlKullaniciTipleri">
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
    <div class="DuyuruOrtaGovde">

        <telerik:RadGrid ID="grdYetkiler" runat="server" CellSpacing="0" DataSourceID="SqlDataSource1" GridLines="None"
            AllowAutomaticUpdates="True"                     
            CommandItemDisplay="Top" 
            OnItemUpdated="RadGrid1_ItemUpdated" OnItemDataBound="grdYetkiler_ItemDataBound">

            <ClientSettings>
                <Selecting AllowRowSelect="True" />
            </ClientSettings>

            <MasterTableView AutoGenerateColumns="False" DataSourceID="SqlDataSource1"  EditMode="Batch" DataKeyNames="FormId, KullaniciTipiId" CommandItemDisplay="Top" ShowHeader="false" >
            
                <BatchEditingSettings EditType="Cell" />
                <GroupByExpressions>
                    <telerik:GridGroupByExpression>                      
                        <SelectFields>                            
                            <telerik:GridGroupByField FieldAlias="Grup" FieldName="FormImageUrl">                                
                            </telerik:GridGroupByField>
                        </SelectFields>

                        <GroupByFields>                                                      
                            <telerik:GridGroupByField FieldName="FormImageUrl">                               
                            </telerik:GridGroupByField>
                        </GroupByFields>                                                                        
                    </telerik:GridGroupByExpression>
                </GroupByExpressions>
            
                <Columns>
                    <telerik:GridBoundColumn DataField="FormBaslik" HeaderText="FormBaslik" SortExpression="FormBaslik" UniqueName="FormBaslik" ReadOnly="true" HeaderStyle-Width="200">
                    </telerik:GridBoundColumn>
                
                    <telerik:GridCheckBoxColumn DataField="FormYetki" DataType="System.Boolean" HeaderText="FormYetki" SortExpression="FormYetki" UniqueName="FormYetki">
                    <ItemStyle HorizontalAlign="Right"></ItemStyle>
                    </telerik:GridCheckBoxColumn>

                </Columns>

                <GroupHeaderTemplate>
                   <asp:Image ID="imgResim" runat="server" />               
                </GroupHeaderTemplate>
                
            </MasterTableView>
        </telerik:RadGrid> 
    </div>
    </telerik:RadAjaxPanel>

    <asp:SqlDataSource ID="SqlKullaniciTipleri" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="Select KullaniciTipId, KullaniciTipAdi From KullaniciTipleri"></asp:SqlDataSource>
     
    <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" 
        SelectCommand="Select FParent.FormBaslik as PFormBaslik, FNormal.FormBaslik, 
                        KF.KullaniciTipiId, KF.FormId, KF.FormYetki, FParent.FormImageUrl From Formlar FParent
                        INNER JOIN Formlar FNormal ON FParent.Id = FNormal.PId
                        LEFT  JOIN KullaniciFormlar KF ON KF.FormId = FNormal.Id 
                        Where KF.KullaniciTipiId = @KullaniciTipiId ORDER BY KF.FormId ASC" 
       UpdateCommand="UPDATE KullaniciFormlar SET FormYetki = @FormYetki WHERE (KullaniciTipiId = @KullaniciTipiId) AND (FormId = @FormId)">
          
        <SelectParameters>
               <asp:ControlParameter ControlID="RadGridKullaniciTipleri" Name="KullaniciTipiId" DefaultValue="1"  PropertyName="SelectedValue">
               </asp:ControlParameter>
          </SelectParameters>  
        
          <UpdateParameters>
             <asp:Parameter Name="FormYetki" />
             <asp:Parameter Name="FormId" />
          </UpdateParameters>
    </asp:SqlDataSource>

</asp:Content>
