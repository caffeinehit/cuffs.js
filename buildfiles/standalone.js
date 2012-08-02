// Build cuffs without require.js dependency
({
  baseUrl: "../lib",
  modules: [
    {name: 'cuffs/cuffs'}    
  ],
  out: "../cuffs.standalone.min.js"
})
