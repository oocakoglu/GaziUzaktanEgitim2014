using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Telerik.Web.UI;

namespace GaziProje2014
{


    public partial class Site : System.Web.UI.MasterPage
    {
        private class Formlar
        {
            public int Id { get; set; }
            public int? PId { get; set; }
            public string FormAdi { get; set; }
            public string FormBaslik { get; set; }
            public string FormAciklama { get; set; }
        }  

        private void FormCreateNode(int? AktifParentId, RadPanelItem RootNode, List<Formlar> FormList)
        {

            List<Formlar> FormBaslik = FormList.Where(x => x.PId == AktifParentId).ToList();

            foreach (Formlar items in FormBaslik)
            {
                RadPanelItem dateItem = new RadPanelItem();
                dateItem.Text = items.FormBaslik;
                dateItem.CssClass = "MainItem";
                dateItem.NavigateUrl = items.FormAdi;
                dateItem.ImageUrl = "http://demos.telerik.com/aspnet-ajax/panelbar/examples/overview/Images/contacts.gif";
                //RadPanelBar1.Items.Add(dateItem);

                if (RootNode != null)
                    RootNode.Items.Add(dateItem);
                else
                    RadPanelBar1.Items.Add(dateItem);

                FormCreateNode(items.Id, dateItem, FormList);
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {

            if (!Page.IsPostBack)
            {              
                string ConStr = ConfigurationManager.ConnectionStrings["GAZIConnectionString"].ConnectionString;
                SqlDataAdapter daForm = new SqlDataAdapter("SELECT Id, PId, FormAdi, FormBaslik, FormAciklama, FormImageUrl FROM Formlar", ConStr);
                DataTable dtForm = new DataTable();
                daForm.Fill(dtForm);

                List<Formlar> aa = dtForm.AsEnumerable().Select(row =>
                    new Formlar
                    {
                        Id = row.Field<int>("Id"),
                        PId = row.Field<int?>("PId"),
                        FormAdi = row.Field<string>("FormAdi"),
                        FormBaslik = row.Field<string>("FormBaslik"),
                        FormAciklama = row.Field<string>("FormAciklama")
                    }).ToList();



                FormCreateNode(null, null, aa);


                RadPanelItem dateItem = new RadPanelItem();
                dateItem.Text = "Sabit Menüler";
                dateItem.CssClass = "MainItem";
                dateItem.Expanded = true;
                dateItem.ImageUrl = "http://demos.telerik.com/aspnet-ajax/panelbar/examples/overview/Images/contacts.gif";
                RadPanelBar1.Items.Add(dateItem);

                RadPanelItem yearItem = new RadPanelItem();
                yearItem.Text = "Sabit Menü1 ";
                dateItem.Items.Add(yearItem);

                RadPanelItem monthItem = new RadPanelItem();
                monthItem.Text = "Sabit Menü2 ";
                dateItem.Items.Add(monthItem);
                
                RadPanelItem dayItem = new RadPanelItem();
                dayItem.Text = "Sabit Menü3 ";
                dateItem.Items.Add(dayItem);

          
                RadPanelItem DersItem = new RadPanelItem();
                DersItem.ImageUrl = "http://demos.telerik.com/aspnet-ajax/panelbar/examples/overview/Images/notes.gif";
                DersItem.Text = "Ders Ağaç Yapısı";
                DersItem.CssClass = "MainItem";
                RadPanelBar1.Items.Add(DersItem);

                RadPanelItem KonuItem = new RadPanelItem();
                //KonuItem.Text = "Hours : " + DateTime.Now.Hour.ToString();
                DersItem.Items.Add(KonuItem);
                KonuItem.DataBind();

                //RadPanelItem MersItem = new RadPanelItem();
                //MersItem.Text = "Hours : " + DateTime.Now.Hour.ToString();
                //DersItem.Items.Add(MersItem);

                //DersItem.Items.Add(new RadPanelItem("PanelItem1"));




                //RadPanelBar1.Items.Add(new RadPanelItem("PanelItem2"));
            }
           


        }

        protected override void OnInit(EventArgs e)
        {
            RadPanelBar1.ItemTemplate = new TextBoxTemplate(); base.OnInit(e);
        }

        class TextBoxTemplate : ITemplate
        {
            public void InstantiateIn(Control container)
            {
                //string ConStr = ConfigurationManager.ConnectionStrings["GAZIConnectionString"].ConnectionString;
                //SqlDataAdapter daForm = new SqlDataAdapter("SELECT Id, PId, FormAdi, FormBaslik, FormAciklama, FormIcon FROM Formlar", ConStr);
                //DataTable dtForm = new DataTable();
                //daForm.Fill(dtForm);

                //RadTreeView radTreeView = new RadTreeView();
                //radTreeView.ID = "radTreeView1";
                //radTreeView.DataFieldID = "Id";
                //radTreeView.DataFieldParentID = "PId";
                //radTreeView.DataNavigateUrlField = "FormAdi";
                //radTreeView.DataTextField = "FormBaslik";
                //radTreeView.DataValueField = "Id";

                //radTreeView.DataSource = dtForm;
                //container.Controls.Add(radTreeView);
            }

        }
    
    }
}