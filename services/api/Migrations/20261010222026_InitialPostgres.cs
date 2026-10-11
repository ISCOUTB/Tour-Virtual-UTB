using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace TourVirtualUTB.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialPostgres : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Lugares",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Nombre = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Slug = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Lugares", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Rutas",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    LugarId = table.Column<int>(type: "integer", nullable: false),
                    Nombre = table.Column<string>(type: "text", nullable: false),
                    Descripcion = table.Column<string>(type: "text", nullable: true),
                    Audiencia = table.Column<int>(type: "integer", nullable: false),
                    Activa = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Rutas", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Rutas_Lugares_LugarId",
                        column: x => x.LugarId,
                        principalTable: "Lugares",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Escenas",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    LugarId = table.Column<int>(type: "integer", nullable: false),
                    PoiId = table.Column<int>(type: "integer", nullable: true),
                    ImagenUrl = table.Column<string>(type: "text", nullable: false),
                    ImagenUrlBaja = table.Column<string>(type: "text", nullable: true),
                    Nombre = table.Column<string>(type: "text", nullable: true),
                    EsEscenaPrincipal = table.Column<bool>(type: "boolean", nullable: false),
                    Orden = table.Column<int>(type: "integer", nullable: false),
                    VistaInicialYaw = table.Column<double>(type: "double precision", nullable: true),
                    VistaInicialPitch = table.Column<double>(type: "double precision", nullable: true)
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
                name: "Pois",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    LugarId = table.Column<int>(type: "integer", nullable: false),
                    Nombre = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Categoria = table.Column<string>(type: "text", nullable: true),
                    Descripcion = table.Column<string>(type: "text", nullable: true),
                    Lat = table.Column<double>(type: "double precision", nullable: true),
                    Lng = table.Column<double>(type: "double precision", nullable: true),
                    MapX = table.Column<double>(type: "double precision", nullable: true),
                    MapY = table.Column<double>(type: "double precision", nullable: true),
                    Audiencias = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Activo = table.Column<bool>(type: "boolean", nullable: false),
                    EscenaPrincipalId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Pois", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Pois_Escenas_EscenaPrincipalId",
                        column: x => x.EscenaPrincipalId,
                        principalTable: "Escenas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Pois_Lugares_LugarId",
                        column: x => x.LugarId,
                        principalTable: "Lugares",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Hotspots",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    EscenaId = table.Column<int>(type: "integer", nullable: false),
                    Tipo = table.Column<int>(type: "integer", nullable: false),
                    Pitch = table.Column<double>(type: "double precision", nullable: false),
                    Yaw = table.Column<double>(type: "double precision", nullable: false),
                    EscenaDestinoId = table.Column<int>(type: "integer", nullable: true),
                    PoiId = table.Column<int>(type: "integer", nullable: true),
                    Etiqueta = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Hotspots", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Hotspots_Escenas_EscenaDestinoId",
                        column: x => x.EscenaDestinoId,
                        principalTable: "Escenas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Hotspots_Escenas_EscenaId",
                        column: x => x.EscenaId,
                        principalTable: "Escenas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Hotspots_Pois_PoiId",
                        column: x => x.PoiId,
                        principalTable: "Pois",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Medios",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PoiId = table.Column<int>(type: "integer", nullable: false),
                    Tipo = table.Column<int>(type: "integer", nullable: false),
                    Url = table.Column<string>(type: "text", nullable: false),
                    Orden = table.Column<int>(type: "integer", nullable: false),
                    DuracionSeg = table.Column<int>(type: "integer", nullable: true),
                    TextoAlt = table.Column<string>(type: "text", nullable: true),
                    SubtitulosUrl = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Medios", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Medios_Pois_PoiId",
                        column: x => x.PoiId,
                        principalTable: "Pois",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "RutaPois",
                columns: table => new
                {
                    RutaId = table.Column<int>(type: "integer", nullable: false),
                    PoiId = table.Column<int>(type: "integer", nullable: false),
                    Orden = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RutaPois", x => new { x.RutaId, x.PoiId });
                    table.ForeignKey(
                        name: "FK_RutaPois_Pois_PoiId",
                        column: x => x.PoiId,
                        principalTable: "Pois",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_RutaPois_Rutas_RutaId",
                        column: x => x.RutaId,
                        principalTable: "Rutas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Escenas_LugarId",
                table: "Escenas",
                column: "LugarId");

            migrationBuilder.CreateIndex(
                name: "IX_Escenas_PoiId",
                table: "Escenas",
                column: "PoiId");

            migrationBuilder.CreateIndex(
                name: "IX_Hotspots_EscenaDestinoId",
                table: "Hotspots",
                column: "EscenaDestinoId");

            migrationBuilder.CreateIndex(
                name: "IX_Hotspots_EscenaId",
                table: "Hotspots",
                column: "EscenaId");

            migrationBuilder.CreateIndex(
                name: "IX_Hotspots_PoiId",
                table: "Hotspots",
                column: "PoiId");

            migrationBuilder.CreateIndex(
                name: "IX_Lugares_Slug",
                table: "Lugares",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Medios_PoiId",
                table: "Medios",
                column: "PoiId");

            migrationBuilder.CreateIndex(
                name: "IX_Pois_EscenaPrincipalId",
                table: "Pois",
                column: "EscenaPrincipalId");

            migrationBuilder.CreateIndex(
                name: "IX_Pois_LugarId",
                table: "Pois",
                column: "LugarId");

            migrationBuilder.CreateIndex(
                name: "IX_RutaPois_PoiId",
                table: "RutaPois",
                column: "PoiId");

            migrationBuilder.CreateIndex(
                name: "IX_Rutas_LugarId",
                table: "Rutas",
                column: "LugarId");

            migrationBuilder.AddForeignKey(
                name: "FK_Escenas_Pois_PoiId",
                table: "Escenas",
                column: "PoiId",
                principalTable: "Pois",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Escenas_Lugares_LugarId",
                table: "Escenas");

            migrationBuilder.DropForeignKey(
                name: "FK_Pois_Lugares_LugarId",
                table: "Pois");

            migrationBuilder.DropForeignKey(
                name: "FK_Escenas_Pois_PoiId",
                table: "Escenas");

            migrationBuilder.DropTable(
                name: "Hotspots");

            migrationBuilder.DropTable(
                name: "Medios");

            migrationBuilder.DropTable(
                name: "RutaPois");

            migrationBuilder.DropTable(
                name: "Rutas");

            migrationBuilder.DropTable(
                name: "Lugares");

            migrationBuilder.DropTable(
                name: "Pois");

            migrationBuilder.DropTable(
                name: "Escenas");
        }
    }
}
