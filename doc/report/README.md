# p6 Report

## Notes Noah
### Measurements to do
* [ ] Latency of receiving path (from PHY to UFT out stream)
* [ ] ILA/Trace measurement showing slow output pixels solution A

### Graphics to draw
* [x] Dataflow block diagram for solution A (with memory)
* [x] Dataflow block diagram for solution B (stream)
* [x] Graphic for memory layout solution A
* [x] dc top block design
* [x] simple FiFo overview
* [x] Graphic for memory layout solution B

### Code to correct
* [ ] Change all row_* pointers in dc_mmu to col* pointer which would make sense

### Check with Jan
* [ ] Where do you describe why you need the pixels coloumn wise? ch:ip:concept?
* [ ] if-statements in HLS controller: What did we want to show?
* [ ] Reference to code files - how?