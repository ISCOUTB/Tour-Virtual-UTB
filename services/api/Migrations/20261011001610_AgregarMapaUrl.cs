using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TourVirtualUTB.Api.Migrations
{
    /// <inheritdoc />
    public partial class AgregarMapaUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "MapaUrl",
                table: "Lugares",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MapaUrl",
                table: "Lugares");
        }
    }
}
