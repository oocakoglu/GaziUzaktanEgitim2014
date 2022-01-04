using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Telerik.Web.UI;

namespace GaziProje2014.Pages
{
    public partial class tolga_Sinav_Detay : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void gridHazirSinavlar_ItemCommand(object sender, Telerik.Web.UI.GridCommandEventArgs e)
        {
            GridDataItem item = gridHazirSinavlar.Items[e.Item.ItemIndex];
            string id = string.Empty;

            switch (e.CommandName)
            {
                case "Detay":
                    break;

            }
        }
    }
}