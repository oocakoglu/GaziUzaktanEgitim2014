
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

namespace GaziProje2014.Pages
{
    public partial class tolgaDeneme : System.Web.UI.Page
    {

        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void btnSecilen_Click(object sender, EventArgs e)
        {
            SqlDataSource2.InsertParameters["KullaniciId"].DefaultValue = "1";
            SqlDataSource2.InsertParameters["SinavAdi"].DefaultValue = txtSinavAdi.Text;
            SqlDataSource2.InsertParameters["KayitTrh"].DefaultValue = System.DateTime.Now.ToString();
            SqlDataSource2.Insert();


            foreach (Telerik.Web.UI.RadListViewItem item in RadListView1.SelectedItems)
            {
                SqlDataSource3.InsertParameters["SinavId"].DefaultValue = hdnSinavId.Value;
                SqlDataSource3.InsertParameters["SorularId"].DefaultValue = ((Label)item.FindControl("IdLabel")).Text;
                SqlDataSource3.Insert();

            }
          
        }

        protected void SqlDataSource2_Inserted(object sender, SqlDataSourceStatusEventArgs e)
        {
            e.Command.CommandText = "SELECT @@IDENTITY";
            hdnSinavId.Value = e.Command.ExecuteScalar().ToString();


        }
    }
}