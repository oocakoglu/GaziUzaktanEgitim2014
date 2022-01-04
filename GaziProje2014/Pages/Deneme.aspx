<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Deneme.aspx.cs" Inherits="GaziProje2014.Pages.Deneme" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">



                
            <telerik:RadSplitter ID="RadSplitter1" runat="server" Height="100%" Width="100%">
                <telerik:RadPane ID="RadPane1" runat="server" Width="20%" Height="100%">
                    <div class="qsf-demo-canvas">
<%--                        <telerik:RadPanelBar runat="server" ID="RadPanelBar1"  Height="100%" Width="100%" ExpandMode="FullExpandedItem" >                                                    
                        </telerik:RadPanelBar>--%>
                        <telerik:RadGrid ID="RadGridKullaniciTipleri" runat="server" Height="100%" Width="100%" CellSpacing="0" 
                            DataSourceID="SqlKullaniciTipleri"
                            AllowMultiRowSelection="false">
                            
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
                </telerik:RadPane>
               
                <telerik:RadSplitBar ID="RadSplitbar1" runat="server" CollapseMode="Forward">
                </telerik:RadSplitBar>
              
                <telerik:RadPane ID="contentPane" runat="server" Width="80%" Height="100%">   
                   <div class="qsf-demo-canvas">    
           

                        <telerik:RadGrid ID="RadGrid1" runat="server" CellSpacing="0" DataSourceID="SqlDataSource1" GridLines="None"
                            AllowAutomaticUpdates="True"                     
                            CommandItemDisplay="Top" 
                            OnItemUpdated="RadGrid1_ItemUpdated">

                            <ClientSettings>
                                <Selecting AllowRowSelect="True" />
                            </ClientSettings>



                            <MasterTableView AutoGenerateColumns="False" DataSourceID="SqlDataSource1"  EditMode="Batch" DataKeyNames="FormId, KullaniciTipiId" CommandItemDisplay="Top" ShowHeader="false" >
            
                                <BatchEditingSettings EditType="Cell" />
                                <GroupByExpressions>
                                    <telerik:GridGroupByExpression>
                                        <SelectFields>
                                            <telerik:GridGroupByField FieldAlias="Grup" FieldName="PFormBaslik"></telerik:GridGroupByField>
                                        </SelectFields>
                                        <GroupByFields>
                                            <telerik:GridGroupByField FieldName="PFormBaslik"></telerik:GridGroupByField>
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
                            </MasterTableView>
                        </telerik:RadGrid> 

                      
                   </div>                 
                </telerik:RadPane>   
                              
            </telerik:RadSplitter>                





   
    <asp:SqlDataSource ID="SqlKullaniciTipleri" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="Select KullaniciTipId, KullaniciTipAdi From KullaniciTipleri"></asp:SqlDataSource>
     
    <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" 
        SelectCommand="Select FParent.FormBaslik as PFormBaslik, FNormal.FormBaslik, 
                        KF.KullaniciTipiId, KF.FormId, KF.FormYetki From Formlar FParent
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
<%--    <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" 
        SelectCommand="Select FParent.FormBaslik as PFormBaslik, FNormal.FormBaslik, 
                        KF.KullaniciTipiId, KF.FormId, KF.FormYetki From Formlar FParent
                        INNER JOIN Formlar FNormal ON FParent.Id = FNormal.PId
                        LEFT  JOIN KullaniciFormlar KF ON KF.FormId = FNormal.Id 
                        Where KF.KullaniciTipiId = 1">
    </asp:SqlDataSource>--%>








</asp:Content>
