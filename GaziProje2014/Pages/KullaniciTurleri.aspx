<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="KullaniciTurleri.aspx.cs" Inherits="GaziProje2014.Pages.KullaniciTurleri" %>

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



    <telerik:RadGrid ID="RadGrid1" AutoGenerateEditColumn="true" runat="server" AllowAutomaticDeletes="True"
        AllowAutomaticInserts="True" AllowAutomaticUpdates="True" DataSourceID="SqlDataSource1" AllowPaging="False"
        AllowSorting="true" >
        <MasterTableView EditMode="PopUp" CommandItemDisplay="Top" DataKeyNames="KullaniciTipId">


            <EditFormSettings InsertCaption="Kullanıcı Tipi Ekle" CaptionFormatString="{0} Detayları"
                CaptionDataField="KullaniciTipAdi" EditFormType="Template" PopUpSettings-Modal="true"
                PopUpSettings-Width="310px" PopUpSettings-Height="132px">
                <FormTemplate>
                   <div style="padding:10px;">

                        <table>
                            <tr>
                                <td>Kullanıcı Tipi Adı
                                </td>
                                <td>
                                    <telerik:RadTextBox ID="txtKullaniciTipiAdi" runat="server" Text='<%# Bind( "KullaniciTipAdi") %>'>
                                    </telerik:RadTextBox>
                                </td>
                            </tr>
                            <tr>
                                <td>Kullanıcı Tipi Açıklama
                                </td>
                                <td rowspan="2">
                                    <telerik:RadTextBox ID="txtKullaniciTipAciklama" runat="server" Text='<%# Bind( "KullaniciTipAciklama") %>'>
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

    <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>"
        SelectCommand="SELECT [KullaniciTipId], [KullaniciTipAdi], [KullaniciTipAciklama] FROM [KullaniciTipleri]"
        DeleteCommand="DELETE FROM [KullaniciTipleri] WHERE [KullaniciTipId] = @KullaniciTipId"
        InsertCommand="INSERT INTO [KullaniciTipleri] ([KullaniciTipAdi], [KullaniciTipAciklama]) VALUES (@KullaniciTipAdi, @KullaniciTipAciklama)"
        UpdateCommand="UPDATE [KullaniciTipleri] SET [KullaniciTipAdi] = @KullaniciTipAdi, [KullaniciTipAciklama] = @KullaniciTipAciklama WHERE [KullaniciTipId] = @KullaniciTipId">
        <DeleteParameters>
            <asp:Parameter Name="KullaniciTipId" Type="Int32" />
        </DeleteParameters>
        <InsertParameters>
            <asp:Parameter Name="KullaniciTipAdi" Type="String" />
            <asp:Parameter Name="KullaniciTipAciklama" Type="String" />
        </InsertParameters>
        <UpdateParameters>
            <asp:Parameter Name="KullaniciTipAdi" Type="String" />
            <asp:Parameter Name="KullaniciTipAciklama" Type="String" />
            <asp:Parameter Name="KullaniciTipId" Type="Int32" />
        </UpdateParameters>
    </asp:SqlDataSource>


</asp:Content>
