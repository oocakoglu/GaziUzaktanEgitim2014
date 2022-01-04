<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SinavSoruSecim.aspx.cs" Inherits="GaziProje2014.Forms.SinavSoruSecim" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <link href="../Style/css/Site.css" rel="stylesheet" />
    <link href="../Style/css/Site.css" rel="stylesheet" type="text/css" />
    <style>
        .SolSorular {
            position: absolute;
            top: 40px;
            left: 0px;
            bottom: 40px;
            width: 500px;
            overflow: scroll;
            overflow-x: hidden;
            background-color: white;
            opacity: 0.9;
            filter: alpha(opacity=90);
        }

        .SagSorular {
            position: absolute;
            top: 40px;
            left: 500px;
            bottom: 40px;
            right: 0px;
            padding: 10px;
            overflow: scroll;
            overflow-x: hidden;
            background-color: white;
            opacity: 0.9;
            filter: alpha(opacity=90);
        }
    </style>

</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server"></telerik:RadScriptManager>

        <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">
            <script type="text/javascript">
                function CloseAndRebind(args) {
                    GetRadWindow().BrowserWindow.refreshGrid(args);
                    GetRadWindow().close();
                }

                function GetRadWindow() {
                    var oWindow = null;
                    if (window.radWindow) oWindow = window.radWindow;
                    else if (window.frameElement.radWindow)
                        oWindow = window.frameElement.radWindow;
                    return oWindow;
                }

                function CancelEdit() {
                    GetRadWindow().close();
                }

            </script>
        </telerik:RadCodeBlock>

            <asp:UpdatePanel ID="UpdatePanel1" runat="server" UpdateMode="Conditional">
                <ContentTemplate>

                <div class="contentUst40">
                    <table class="tdTablo">
                        <tr>
                            <td class="tdCellBaslik">Ders Adı :</td>
                            <td colspan="4">
                                <telerik:RadComboBox ID="rdDersler" runat="server" Width="500px" OnSelectedIndexChanged="rdDersler_SelectedIndexChanged" AutoPostBack="true">
                                </telerik:RadComboBox>
                            </td>
                            <td class="tdCellBaslik"></td>
                        </tr>
                    </table>
                </div>
                <div class="contentUst40Golge">
                </div>



                <div class="SolSorular">
                    <telerik:RadGrid ID="grdSorular" runat="server" OnSelectedIndexChanged="grdSorular_SelectedIndexChanged">
                        <ClientSettings EnableRowHoverStyle="true" EnablePostBackOnRowClick="true">
                            <Selecting AllowRowSelect="true"></Selecting>
                        </ClientSettings>

                        <ClientSettings  EnableRowHoverStyle="true">
                            <Selecting AllowRowSelect="True" />
                        </ClientSettings>

                        <MasterTableView AutoGenerateColumns="False" DataKeyNames="SoruId">
                            <Columns>
                                <telerik:GridTemplateColumn UniqueName="chkTemplateColumn" Reorderable="False" Groupable="False">
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chksoruSec" runat="server" AutoPostBack="False"></asp:CheckBox>
                                    </ItemTemplate>
                                    <HeaderStyle Width="40px" />
                                </telerik:GridTemplateColumn>

                                <telerik:GridBoundColumn  DataField="SoruId" ReadOnly="True" UniqueName="SoruId" DataType="System.Int32"  Display="false">
                                    <ColumnValidationSettings>
                                        <ModelErrorMessage Text="" />
                                    </ColumnValidationSettings>
                                </telerik:GridBoundColumn>

                                <telerik:GridBoundColumn DataField="SoruKonu" HeaderText="SoruKonu" UniqueName="SoruKonu">
                                    <ColumnValidationSettings>
                                        <ModelErrorMessage Text="" />
                                    </ColumnValidationSettings>
                                    <HeaderStyle Width="120px" />
                                </telerik:GridBoundColumn>

                                <telerik:GridBoundColumn DataField="SoruIcerik" HeaderText="SoruIcerik" UniqueName="SoruIcerik">
                                    <ColumnValidationSettings>
                                        <ModelErrorMessage Text="" />
                                    </ColumnValidationSettings>
                                </telerik:GridBoundColumn>

                            </Columns>
                        </MasterTableView>

                    </telerik:RadGrid>

                </div>

                <div class="SagSorular" id="dvSag">

                    <fieldset class="fieldsetForm">
                        <legend class="legendForm">&nbsp;Soru&nbsp;</legend>
                        <asp:Image ID="imgSoruResim" runat="server" /><br />
                        <asp:Label ID="lblSoruIcerik" runat="server" Text="Soruyu görüntüleyebilmek için sol taraftan soru seçiniz" />
                        <asp:RadioButtonList ID="rdCevaplar" runat="server" Enabled="false">
                        </asp:RadioButtonList>
                    </fieldset>

                </div>
              
                  </ContentTemplate>
                </asp:UpdatePanel>

                <div class="contentAlt30">
                    

                    <telerik:RadButton Width="100px" ID="btnTamam" runat="server" Text="Tamam" OnClick="btnTamam_Click">
                    </telerik:RadButton>

                    <telerik:RadButton Width="100px" ID="btnIptal" runat="server" Text="İptal" OnClick="btnIptal_Click">
                    </telerik:RadButton>

                </div>

                <div class="contentAlt30Golge">
                </div>
                <asp:HiddenField ID="hdnOgretmenDersId" runat="server" />

            
    </form>
</body>
</html>
