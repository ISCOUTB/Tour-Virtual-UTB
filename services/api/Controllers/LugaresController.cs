using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Data;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LugaresController : ControllerBase
    {
        private readonly TourDbContext _context;

        public LugaresController(TourDbContext context)
        {
            _context = context;
        }

        // GET: api/Lugares -> Lo usará Flutter para pintar los pines
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Lugar>>> GetLugares()
        {
            // Devuelve todos los lugares guardados en la BD
            return await _context.Lugares.ToListAsync();
        }

        // POST: api/Lugares -> Lo usará el Administrador para registrar un edificio
        [HttpPost]
        public async Task<ActionResult<Lugar>> PostLugar(Lugar lugar)
        {
            _context.Lugares.Add(lugar);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetLugares), new { id = lugar.Id }, lugar);
        }
    }
}