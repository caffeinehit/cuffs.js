// Build cuffs without require.js dependency
({
  baseUrl: "./lib",
  modules: [
    {name: 'cuffs/main'}    
  ],
  out: "build/cuffs.standalone.min.js"
})
