<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="DuyuruDetay.aspx.cs" Inherits="GaziProje2014.Pages.DuyuruDetay" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <table cellspacing="0" cellpadding="0">
          <tr>
               <td style="vertical-align: top;">
                    <asp:UpdatePanel ID="UpdatePanel1" runat="server">
                         <ContentTemplate>
                              <telerik:RadEditor runat="server" ID="RadEditor1" SkinID="DefaultSetOfTools" Height="675px">
                                   <ImageManager ViewPaths="~/Editor/Img/UserDir/Marketing,~/Editor/Img/UserDir/PublicRelations"
                                        UploadPaths="~/Editor/Img/UserDir/Marketing,~/Editor/Img/UserDir/PublicRelations"
                                        DeletePaths="~/Editor/Img/UserDir/Marketing,~/Editor/Img/UserDir/PublicRelations"
                                        EnableAsyncUpload="true"></ImageManager>
                              </telerik:RadEditor>
                         </ContentTemplate>
                         <Triggers>
                              <asp:AsyncPostBackTrigger ControlID="CheckBoxListEditMode"></asp:AsyncPostBackTrigger>
                              <asp:AsyncPostBackTrigger ControlID="RadioButtonListEditMode"></asp:AsyncPostBackTrigger>
                              <asp:AsyncPostBackTrigger ControlID="CheckBoxListModules"></asp:AsyncPostBackTrigger>
                              <asp:AsyncPostBackTrigger ControlID="RadioButtonListEnabled"></asp:AsyncPostBackTrigger>
                              <%--<asp:AsyncPostBackTrigger ControlID="ChooseToolbarMode" />--%>
                         </Triggers>
                    </asp:UpdatePanel>
               </td>
               <td style="padding: 0 0 0 50px; vertical-align: top;" id="decorationZoneElement">
                    <qsf:ConfiguratorPanel runat="server" ID="ConfigurationPanel1" Enabled="true" Title="Configure RadEditor"
                         Expanded="true" Style="text-align: left;" HorizontalAlign="Right" Width="280">
                         <asp:UpdatePanel ID="UpdatePanel2" runat="server" UpdateMode="Conditional">
                              <ContentTemplate>
                                   <div style="padding: 8px;">
                                        <strong>Change Edit Mode:</strong>
                                        <asp:Label ID="lblEditModes" runat="server" EnableViewState="false"></asp:Label>
                                        <asp:CheckBoxList RepeatDirection="Vertical" Width="280px" CellPadding="0" CellSpacing="0"
                                             OnSelectedIndexChanged="CheckBoxListEditMode_SelectedIndexChanged" CssClass="text"
                                             ID="CheckBoxListEditMode" runat="server" AutoPostBack="True">
                                             <asp:ListItem Value="Design" Selected="True">Design Mode</asp:ListItem>
                                             <asp:ListItem Value="Html" Selected="True">Html Mode</asp:ListItem>
                                             <asp:ListItem Value="Preview" Selected="True">Preview Mode</asp:ListItem>
                                        </asp:CheckBoxList>
                                   </div>
                                   <div style="padding: 8px;">
                                        <strong>Choose tools file:</strong>
                                        <asp:RadioButtonList RepeatDirection="Vertical" Width="280px" CellPadding="0" CellSpacing="0"
                                             OnSelectedIndexChanged="RadioButtonListEditMode_SelectedIndexChanged" CssClass="text"
                                             ID="RadioButtonListEditMode" runat="server" AutoPostBack="True">
                                             <asp:ListItem Value="FullSet">Full set of tools</asp:ListItem>
                                             <asp:ListItem Value="Default" Selected="True">Default</asp:ListItem>
                                             <asp:ListItem Value="BasicTools">Basic toolset</asp:ListItem>
                                        </asp:RadioButtonList>
                                   </div>
                                   <div style="padding: 8px;">
                                        <strong>Choose module:</strong>
                                        <asp:CheckBoxList RepeatDirection="Vertical" Width="280px" CellPadding="0" CellSpacing="0"
                                             OnSelectedIndexChanged="CheckBoxListModules_SelectedIndexChanged" CssClass="text"
                                             ID="CheckBoxListModules" runat="server" AutoPostBack="True">
                                             <asp:ListItem Value="RadEditorStatistics" Selected="true">Rad Editor Statistics</asp:ListItem>
                                             <asp:ListItem Value="RadEditorDomInspector" Selected="true">Rad Editor Dom Inspector</asp:ListItem>
                                             <asp:ListItem Value="RadEditorNodeInspector" Selected="true">Rad Editor Node Inspector</asp:ListItem>
                                        </asp:CheckBoxList>
                                   </div>
                                   <div style="padding: 8px;">
                                        <strong>Enable/Disable RadEditor:</strong>
                                        <asp:RadioButtonList ID="RadioButtonListEnabled" Width="280px" runat="server" AutoPostBack="true"
                                             RepeatDirection="Vertical" CssClass="text" CellPadding="0" CellSpacing="0" OnSelectedIndexChanged="RadioButtonListEnabled_SelectedIndexChanged">
                                             <asp:ListItem Value="Enable" Selected="true">Enable</asp:ListItem>
                                             <asp:ListItem Value="Disable">Disable</asp:ListItem>
                                        </asp:RadioButtonList>
                                   </div>
                                   <div style="padding: 8px;">
                                        <strong>New Lines as:</strong>
                                        <asp:RadioButtonList ID="NewLineBrButtonList" Width="280px" runat="server" AutoPostBack="true"
                                             RepeatDirection="Vertical" CssClass="text" CellPadding="0" CellSpacing="0" OnSelectedIndexChanged="NewLineBrButtonList_SelectedIndexChanged">
                                             <asp:ListItem Value="Br" Selected="true">Breaks</asp:ListItem>
                                             <asp:ListItem Value="P">Paragraphs</asp:ListItem>
                                             <asp:ListItem Value="Div">Divs</asp:ListItem>
                                        </asp:RadioButtonList>
                                   </div>
                              </ContentTemplate>
                         </asp:UpdatePanel>
                         <div style="padding: 5px">
                              <strong>Toolbar Mode:</strong>
                              <telerik:RadComboBox AutoPostBack="true" ID="ChooseToolbarMode" runat="server" OnSelectedIndexChanged="ChooseToolbarMode_SelectedIndexChanged"
                                   Width="200">
                                   <Items>
                                        <telerik:RadComboBoxItem runat="server" Selected="True" Text="Default" Value="Default">
                                        </telerik:RadComboBoxItem>
                                        <telerik:RadComboBoxItem runat="server" Text="PageTop" Value="PageTop"></telerik:RadComboBoxItem>
                                        <telerik:RadComboBoxItem runat="server" Text="ShowOnFocus" Value="ShowOnFocus"></telerik:RadComboBoxItem>
                                        <telerik:RadComboBoxItem runat="server" Text="Floating" Value="Floating"></telerik:RadComboBoxItem>
                                        <telerik:RadComboBoxItem runat="server" Text="RibbonBar" Value="RibbonBar"></telerik:RadComboBoxItem>
                                        <telerik:RadComboBoxItem runat="server" Text="RibbonBarFloating" Value="RibbonBarFloating">
                                        </telerik:RadComboBoxItem>
                                        <telerik:RadComboBoxItem runat="server" Text="RibbonBarPageTop" Value="RibbonBarPageTop">
                                        </telerik:RadComboBoxItem>
                                        <telerik:RadComboBoxItem runat="server" Text="RibbonBarShowOnFocus" Value="RibbonBarShowOnFocus">
                                        </telerik:RadComboBoxItem>
                                   </Items>
                                   <CollapseAnimation Duration="200" Type="OutQuint"></CollapseAnimation>
                              </telerik:RadComboBox>
                              <span style="color: red; font-size: 11px; display: block;">* Note that RadRibbonbar
                                   still does not offer MetroTouch Skin</span>
                         </div>
                    </qsf:ConfiguratorPanel>
               </td>
          </tr>
     </table>
     <div class="qsf-overview-qr">
        <p>
            <asp:Image ID="Image1" runat="server" ImageUrl="~/Common/Images/QrCodesOverview/Editor.png" AlternateText="tlrk.it/1dSIrex" />
            To test the behavior of our controls on mobile devices, scan the QR code.
        </p>
        <a href="http://tlrk.it/1dSIrex">tlrk.it/1dSIrex</a>
    </div>

</asp:Content>
