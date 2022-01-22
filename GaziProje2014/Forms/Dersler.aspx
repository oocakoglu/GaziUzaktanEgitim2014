<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="Dersler.aspx.cs" Inherits="GaziProje2014.Forms.Dersler" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <div class="contentUst40">
        <table class="tdTablo">
            <tr>
                <td class="tdCellBaslik">Ders Adı :</td>
                <td class="tdCellIcerik">
                    <telerik:RadTextBox ID="txtDersAdi" runat="server"></telerik:RadTextBox></td>
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
        <telerik:RadGrid ID="grdDersler"
            OnNeedDataSource="grdDersler_NeedDataSource"
            OnItemCommand="grdDersler_ItemCommand"
            AllowSorting="True"
            runat="server" AllowMultiRowSelection="True"
            AllowMultiRowEdit="True">
            <ExportSettings>
                <Pdf PageWidth="">
                </Pdf>
            </ExportSettings>
            <ClientSettings EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="DersId"  CommandItemDisplay="Top">
                <EditFormSettings InsertCaption="Ders Ekle" CaptionFormatString="{0} Detayları"
                    CaptionDataField="DersAdi" EditFormType="Template" PopUpSettings-Modal="true"
                    PopUpSettings-Width="310px" PopUpSettings-Height="132px">
                    <FormTemplate>
                       <div style="padding:10px;">                     
                            <table>
                                <tr>
                                    <input runat="server" type="hidden" id="dersId" name="dersId" value='<%# Eval("DersId") %>'/>                  
                                </tr>
                                <tr>
                                    <td>Ders Adı
                                    </td>
                                    <td>
                                        <telerik:RadTextBox ID="txtDersAdi" runat="server" Text='<%# Bind( "DersAdi") %>'>
                                        </telerik:RadTextBox>
                                    </td>
                                </tr>
                                <tr>
                                    <td>Ders Açıklama
                                    </td>
                                    <td rowspan="2">
                                        <telerik:RadTextBox ID="txtDersAciklama" runat="server" Text='<%# Bind( "DersAciklama") %>'>
                                        </telerik:RadTextBox>
                                    </td>
                                </tr>
                                <tr>
                                    <td></td>
                                </tr>
                                <tr>
                                    <td>
                                        <telerik:RadButton ID="btnUpdate" Text='<%# (Container is GridEditFormInsertItem) ? "Ekle" : "Güncelle" %>'
                                            runat="server" CommandName='<%# (Container is GridEditFormInsertItem) ? "PerformInsert" : "Update" %>'>
                                        </telerik:RadButton>
                                    </td>
                                    <td>
                                        <telerik:RadButton ID="RadButton4" runat="server" Text="İptal" CausesValidation="False" CommandName="Cancel">
                                        </telerik:RadButton>
                                    </td>
                                </tr>
                            </table>
                  
                      </div>
                    </FormTemplate>
                    <PopUpSettings Modal="True"></PopUpSettings>
                </EditFormSettings>

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




</asp:Content>
