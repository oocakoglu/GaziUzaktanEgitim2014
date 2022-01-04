using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace GaziProje2014.Pages
{
    public partial class TolgaDeneme_Datayok : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            DataTable dtders = new DataTable();
            dtders.Columns.Add(new DataColumn("Id", typeof(System.Int32)));
            dtders.Columns.Add(new DataColumn("DersAdi", typeof(System.String)));
            dtders.Columns.Add(new DataColumn("Kullanci", typeof(System.String)));


            DataRow drDers = dtders.NewRow();
            drDers["Id"] = 1;
            drDers["DersAdi"] = "Matematik";
            drDers["Kullanci"] = "Ömer";


            dtders.Rows.Add(drDers);

            drDers = dtders.NewRow();
            drDers["Id"] = 2;
            drDers["DersAdi"] = "Fizik";
            drDers["Kullanci"] = "Tolga";

            dtders.Rows.Add(drDers);

            drDers = dtders.NewRow();
            drDers["Id"] = 3;
            drDers["DersAdi"] = "Kimya";
            drDers["Kullanci"] = "Melda";


            dtders.Rows.Add(drDers);

            RadGrid1.DataSource = dtders;
            RadGrid1.DataBind();

            RadGrid2.DataSource = dtders;
            RadGrid2.DataBind();
        }
    }
}