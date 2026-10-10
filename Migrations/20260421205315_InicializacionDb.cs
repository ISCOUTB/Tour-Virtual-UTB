using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TourVirtualUTB.Api.Migrations
{
    /// <inheritdoc />
    public partial class InicializacionDb : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Lugares",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Nombre = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Categoria = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Latitud = table.Column<double>(type: "float", nullable: false),
                    Longitud = table.Column<double>(type: "float", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Lugares", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Escenas",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    LugarId = table.Column<int>(type: "int", nullable: false),
                    ImagenUrl = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    EsPanoramica = table.Column<bool>(type: "bit", nullable: false),
                    EsEscenaPrincipal = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Escenas", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Escenas_Lugares_LugarId",
                        column: x => x.LugarId,
                        principalTable: "Lugares",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Hotspots",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EscenaOrigenId = table.Column<int>(type: "int", nullable: false),
                    EscenaDestinoId = table.Column<int>(type: "int", nullable: false),
                    Pitch = table.Column<double>(type: "float", nullable: false),
                    Yaw = table.Column<double>(type: "float", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Hotspots", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Hotspots_Escenas_EscenaDestinoId",
                        column: x => x.EscenaDestinoId,
                        principalTable: "Escenas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Hotspots_Escenas_EscenaOrigenId",
                        column: x => x.EscenaOrigenId,
                        principalTable: "Escenas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Escenas_LugarId",
                table: "Escenas",
                column: "LugarId");

            migrationBuilder.CreateIndex(
                name: "IX_Hotspots_EscenaDestinoId",
                table: "Hotspots",
                column: "EscenaDestinoId");

            migrationBuilder.CreateIndex(
                name: "IX_Hotspots_EscenaOrigenId",
                table: "Hotspots",
                column: "EscenaOrigenId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Hotspots");

            migrationBuilder.DropTable(
                name: "Escenas");

            migrationBuilder.DropTable(
                name: "Lugares");
        }
    }
}
