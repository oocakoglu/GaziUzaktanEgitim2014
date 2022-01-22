<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Dersler.aspx.cs" Inherits="GaziProje2014.Pages.Dersler" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

       <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">
        <script type="text/javascript">
            var popUp;
            function PopUpShowing(sender, eventArgs) {
                popUp = eventArgs.get_popUp();
                var gridWidth = sender.get_element().offsetWidth;
                var gridHeight = sender.get_element().offsetHeight;
                var popUpWidth = popUp.style.width.substr(0, popUp.style.width.indexOf("px"));
                var popUpHeight = popUp.style.height.substr(0, popUp.style.height.indexOf("px"));
                popUp.style.left = ((gridWidth - popUpWidth) / 2 + sender.get_element().offsetLeft).toString() + "px";
                popUp.style.top = ((gridHeight - popUpHeight) / 2 + sender.get_element().offsetTop).toString() + "px";
            }
        </script>
    </telerik:RadCodeBlock>



    <telerik:RadGrid ID="grdDersler" AutoGenerateEditColumn="True" runat="server" AllowAutomaticDeletes="True"
        OnNeedDataSource="grdDersler_NeedDataSource"
        OnItemCommand ="grdDersler_ItemCommand" 
        AllowSorting="True" >
        <MasterTableView EditMode="PopUp" CommandItemDisplay="Top" DataKeyNames="DersId" AutoGenerateColumns="True">

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
        </MasterTableView>
        <ClientSettings>
            <ClientEvents OnPopUpShowing="PopUpShowing" />
            <Selecting AllowRowSelect="true" />
        </ClientSettings>
    </telerik:RadGrid>



</asp:Content>
